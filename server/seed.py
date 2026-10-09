"""Load seed_data.json into the database. Existing ids are skipped (no dupes).

Usage: python seed.py
"""
import json
from pathlib import Path

from app import crud, schemas
from app.database import Base, SessionLocal, engine

SEED_FILE = Path(__file__).parent / "seed_data.json"


def main() -> None:
    Base.metadata.create_all(bind=engine)
    raw = json.loads(SEED_FILE.read_text(encoding="utf-8"))

    db = SessionLocal()
    created = 0
    try:
        for item in raw:
            trip_in = schemas.TripIn(**item)
            _, was_created = crud.create_trip(db, trip_in)
            created += int(was_created)
    finally:
        db.close()

    print(f"Seeded {created} new trip(s) out of {len(raw)} in seed file.")


if __name__ == "__main__":
    main()
