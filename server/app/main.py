from datetime import date

from fastapi import Depends, FastAPI, HTTPException, Response
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session

from . import crud, schemas
from .database import Base, engine, get_db

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Shift Diary API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/health")
def health():
    return {"status": "ok"}


@app.get("/trips", response_model=list[schemas.TripOut])
def list_trips(date: date, db: Session = Depends(get_db)):
    trips = crud.get_trips_for_day(db, date.isoformat())
    return trips


@app.get("/summary", response_model=schemas.DaySummary)
def day_summary(date: date, db: Session = Depends(get_db)):
    return crud.summarize_day(db, date.isoformat())


@app.post("/trips", response_model=schemas.TripOut)
def add_trip(trip: schemas.TripIn, response: Response, db: Session = Depends(get_db)):
    try:
        saved, created = crud.create_trip(db, trip)
    except crud.TripIdConflict as exc:
        raise HTTPException(
            status_code=409,
            detail=f"id '{trip.id}' is already used by a different trip",
        ) from exc
    response.status_code = 201 if created else 200
    return saved
