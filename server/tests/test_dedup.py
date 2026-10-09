TRIP = {
    "id": "t1",
    "start": "2026-10-01T08:10:00+05:00",
    "end": "2026-10-01T08:32:00+05:00",
    "amount": 2400,
    "payment": "card",
}


def test_resubmitting_the_same_trip_does_not_create_a_duplicate(client):
    first = client.post("/trips", json=TRIP)
    assert first.status_code == 201

    # Same id, same data — a legitimate retry, not a conflict: the server
    # returns the trip saved by the FIRST request as-is (200), instead of
    # inserting a second row or erroring (see test_duplicate_id_with_
    # different_payload_is_rejected for when it DOES error).
    second = client.post("/trips", json=TRIP)
    assert second.status_code == 200

    trips = client.get("/trips", params={"date": "2026-10-01"}).json()
    assert len(trips) == 1

    summary = client.get("/summary", params={"date": "2026-10-01"}).json()
    assert summary["trips_count"] == 1
    assert summary["revenue"] == 2400


def test_resubmitting_many_times_still_counts_once_in_summary(client):
    for _ in range(5):
        client.post("/trips", json=TRIP)

    summary = client.get("/summary", params={"date": "2026-10-01"}).json()
    assert summary["trips_count"] == 1
    assert summary["revenue"] == 2400
    assert summary["commission"] == 360


def test_duplicate_id_with_different_payload_is_rejected(client):
    # Same id must mean "same submission" — reusing it for a different trip
    # is a client bug, not a legitimate retry
    client.post("/trips", json=TRIP)

    changed = {**TRIP, "amount": 9999}
    resp = client.post("/trips", json=changed)
    assert resp.status_code == 409

    # The original trip is untouched.
    trips = client.get("/trips", params={"date": "2026-10-01"}).json()
    assert len(trips) == 1
    assert trips[0]["amount"] == 2400

    summary = client.get("/summary", params={"date": "2026-10-01"}).json()
    assert summary["revenue"] == 2400
