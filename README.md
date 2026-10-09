# Driver Shift Diary

A small test-task app: a FastAPI backend and a Flutter client that compute a
driver's daily summary from their trips — trip count, revenue, commission,
payout, cash/card split — and let the driver browse by day.

## Project Structure

```
server/   FastAPI + SQLAlchemy + SQLite backend, pytest tests
mobile/   Flutter client (Riverpod, Dio, json_serializable)
```

## Requirements

- Python 3.11+
- Flutter 3.x (stable channel) with Android toolchain set up
- An Android emulator or device (the only platform configured in this project)

## Usage

### Server

```bash
cd server
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python seed.py                                           # optional sample data
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000  # :8000, docs at /docs
```

Tests: `.venv\Scripts\python.exe -m pytest -v` (9 tests — summary calc,
dedup/409, validation, commission).

### Mobile Client

```bash
cd mobile
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d <device-id>
```

Backend URL override: `--dart-define=API_BASE_URL=http://host:8000`
- Standard AVD: `10.0.2.2`
- Other emulators (LDPlayer/Nox/MEmu/Genymotion): `adb shell ip route get 8.8.8.8`
- Physical device: your LAN IP

Tests: `flutter test` (2 tests — retry id-stability, summary rendering).

## API

| Method | Path                       | Description                                                    |
|--------|----------------------------|------------------------------------------------------------------|
| GET    | `/trips?date=YYYY-MM-DD`   | List of trips for a day                                         |
| GET    | `/summary?date=YYYY-MM-DD` | Day summary (trip count, revenue, commission, payout, cash/card) |
| POST   | `/trips`                   | Add a trip (body below)                                         |

`POST /trips` body:

```json
{
  "id": "t1",
  "start": "2026-10-01T08:10:00+05:00",
  "end": "2026-10-01T08:32:00+05:00",
  "amount": 2400,
  "payment": "card"
}
```
## Design Notes

- **Commission is server-side and fixed**, not client-supplied — see API
  section above.
- **Duplicate protection is id-based**, not content-based: the client
  generates a UUID v4 once per "add trip" attempt and reuses it across
  retries, so a dropped connection followed by a retry is idempotent
  instead of creating a second trip.
- **Day grouping uses the trip's own UTC offset**, never the reader's
  timezone — for a shift/labour record, "which day" is a fact about where
  and when the trip happened, not about whoever is currently viewing it.
- **Per-day data is cached client-side** (`FutureProvider.family`, one
  provider instance per date) — switching days doesn't refetch data
  already loaded this session; pull-to-refresh explicitly invalidates the
  current day.
