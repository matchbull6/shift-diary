TRIP_1 = {
    "id": "t1",
    "start": "2026-10-01T08:10:00+05:00",
    "end": "2026-10-01T08:32:00+05:00",
    "amount": 2400,
    "payment": "card",
}
TRIP_2 = {
    "id": "t2",
    "start": "2026-10-01T09:05:00+05:00",
    "end": "2026-10-01T09:20:00+05:00",
    "amount": 1500,
    "payment": "cash",
}


def test_summary_matches_example_from_the_task(client):
    client.post("/trips", json=TRIP_1)
    client.post("/trips", json=TRIP_2)

    resp = client.get("/summary", params={"date": "2026-10-01"})
    assert resp.status_code == 200
    body = resp.json()

    assert body["trips_count"] == 2
    assert body["revenue"] == 3900
    assert body["commission"] == 585
    assert body["payout"] == 3315
    assert body["cash"] == 1500
    assert body["card"] == 2400


def test_summary_for_empty_day_is_all_zero(client):
    resp = client.get("/summary", params={"date": "2026-01-01"})
    assert resp.status_code == 200
    body = resp.json()

    assert body == {
        "date": "2026-01-01",
        "trips_count": 0,
        "revenue": 0,
        "commission": 0,
        "payout": 0,
        "cash": 0,
        "card": 0,
    }


def test_trips_only_include_the_requested_day(client):
    other_day_trip = {**TRIP_1, "id": "t3", "start": "2026-10-02T08:10:00+05:00", "end": "2026-10-02T08:32:00+05:00"}
    client.post("/trips", json=TRIP_1)
    client.post("/trips", json=other_day_trip)

    resp = client.get("/trips", params={"date": "2026-10-01"})
    assert resp.status_code == 200
    ids = [t["id"] for t in resp.json()]
    assert ids == ["t1"]


def test_add_trip_rejects_non_positive_amount(client):
    bad = {**TRIP_1, "amount": 0}
    resp = client.post("/trips", json=bad)
    assert resp.status_code == 422


def test_add_trip_rejects_end_before_start(client):
    bad = {**TRIP_1, "end": "2026-10-01T07:00:00+05:00"}
    resp = client.post("/trips", json=bad)
    assert resp.status_code == 422


def test_commission_is_computed_server_side_at_a_fixed_rate(client):
    resp = client.post("/trips", json=TRIP_1)
    assert resp.status_code == 201
    assert resp.json()["commission"] == 360  # 15% of 2400
