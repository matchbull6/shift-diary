from datetime import datetime
from enum import Enum

from pydantic import BaseModel, field_serializer, field_validator, model_validator


class PaymentMethod(str, Enum):
    cash = "cash"
    card = "card"


class TripIn(BaseModel):
    """Trip as submitted by a client. Commission is deliberately not part of
    this contract — it's a platform policy, not something a client gets to
    assert, so the server computes it from a fixed rate (see crud.COMMISSION_RATE)."""

    id: str
    start: datetime
    end: datetime
    amount: float
    payment: PaymentMethod

    @field_validator("id")
    @classmethod
    def id_not_blank(cls, value: str) -> str:
        if not value.strip():
            raise ValueError("id must not be blank")
        return value

    @field_validator("amount")
    @classmethod
    def amount_positive(cls, value: float) -> float:
        if value <= 0:
            raise ValueError("amount must be > 0")
        return value

    @field_validator("start", "end")
    @classmethod
    def require_timezone(cls, value: datetime) -> datetime:
        if value.tzinfo is None:
            raise ValueError("datetime must include a timezone offset")
        return value

    @model_validator(mode="after")
    def end_after_start(self) -> "TripIn":
        if self.end <= self.start:
            raise ValueError("end must be later than start")
        return self


class TripOut(BaseModel):
    """Trip as returned by the API. start/end go out WITHOUT the original
    offset — e.g. "2026-10-01T08:10:00", not "...+05:00". The client only
    ever uses these for wall-clock display (the day/summary grouping is
    already resolved server-side, from the ORIGINAL offset, before this
    model is built) — sending a naive datetime lets it parse straight into
    Dart's DateTime with zero conversion risk, instead of a raw string the
    client has to pick apart by hand. See mobile/lib/models/trip.dart."""

    id: str
    start: str
    end: str
    amount: float
    payment: PaymentMethod
    commission: float

    model_config = {"from_attributes": True}

    @field_serializer("start", "end")
    def strip_offset(self, value: str) -> str:
        return datetime.fromisoformat(value).replace(tzinfo=None).isoformat()


class DaySummary(BaseModel):
    date: str
    trips_count: int
    revenue: float
    commission: float
    payout: float
    cash: float
    card: float
