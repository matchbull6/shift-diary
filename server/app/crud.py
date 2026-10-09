from datetime import datetime
from sqlalchemy import select
from sqlalchemy.orm import Session

from . import models, schemas


COMMISSION_RATE = 0.15


def day_of(dt: datetime) -> str:
    """Calendar date of a timezone-aware datetime, in its own offset."""
    return dt.date().isoformat()


def get_trips_for_day(db: Session, day: str) -> list[models.Trip]:
    stmt = select(models.Trip).where(models.Trip.day == day).order_by(models.Trip.start)
    return list(db.scalars(stmt))


def get_trip(db: Session, trip_id: str) -> models.Trip | None:
    return db.get(models.Trip, trip_id)


class TripIdConflict(Exception):
    """Raised when an id already belongs to a trip with different data.

    Same id must mean "same submission, safe to retry" (see create_trip) —
    if the payload differs, the client has a bug (reused an id, or two
    different trips collided), and silently keeping the original would hide that
    """

    def __init__(self, existing: models.Trip):
        self.existing = existing


def _same_trip(existing: models.Trip, trip_in: schemas.TripIn) -> bool:
    return (
        existing.start == trip_in.start.isoformat()
        and existing.end == trip_in.end.isoformat()
        and existing.amount == trip_in.amount
        and existing.payment == trip_in.payment.value
    )


def create_trip(db: Session, trip_in: schemas.TripIn) -> tuple[models.Trip, bool]:
    """Insert a trip. Returns (trip, created) — created=False means the id
    already existed with the SAME data and no new row was written (duplicate
    submission, safe retry). Raises TripIdConflict if the id already exists
    with DIFFERENT data."""
    existing = get_trip(db, trip_in.id)
    if existing is not None:
        if _same_trip(existing, trip_in):
            return existing, False
        raise TripIdConflict(existing)

    trip = models.Trip(
        id=trip_in.id,
        start=trip_in.start.isoformat(),
        end=trip_in.end.isoformat(),
        day=day_of(trip_in.start),
        amount=trip_in.amount,
        payment=trip_in.payment.value,
        commission=round(trip_in.amount * COMMISSION_RATE, 2),
    )
    db.add(trip)
    db.commit()
    db.refresh(trip)
    return trip, True


def summarize_day(db: Session, day: str) -> schemas.DaySummary:
    trips = get_trips_for_day(db, day)

    revenue = sum(t.amount for t in trips)
    commission = sum(t.commission for t in trips)
    cash = sum(t.amount for t in trips if t.payment == "cash")
    card = sum(t.amount for t in trips if t.payment == "card")

    return schemas.DaySummary(
        date=day,
        trips_count=len(trips),
        revenue=revenue,
        commission=commission,
        payout=revenue - commission,
        cash=cash,
        card=card,
    )
