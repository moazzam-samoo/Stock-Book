from fakes import FakeDb

import firestore_io


def test_11_partially_sold_position_is_included_in_held_tickers_query():
    """A status == "open" filter alone would wrongly exclude a
    partially-sold position that still holds shares and can still carry a
    live targetPrice waiting to fire (PHASE-03C)."""
    db = FakeDb(
        positions=[
            {"id": "p1", "uid": "u1", "data": {"status": "open", "ticker": "ENGRO"}},
            {
                "id": "p2",
                "uid": "u2",
                "data": {"status": "partiallySold", "ticker": "LUCK", "targetPrice": 500.0},
            },
            {"id": "p3", "uid": "u3", "data": {"status": "closed", "ticker": "UBL"}},
        ]
    )

    results = firestore_io.get_held_positions(db)
    tickers = {r["ticker"] for r in results}

    assert "LUCK" in tickers
    assert "UBL" not in tickers  # closed positions hold nothing, correctly excluded
    assert len(results) == 2


def test_get_held_positions_attaches_uid_and_doc_id():
    db = FakeDb(positions=[{"id": "p1", "uid": "u1", "data": {"status": "open", "ticker": "ENGRO"}}])
    [result] = firestore_io.get_held_positions(db)
    assert result["uid"] == "u1"
    assert result["id"] == "p1"


def test_get_watched_alerts_filters_active_and_unsent():
    db = FakeDb(
        price_alerts=[
            {"id": "a1", "uid": "u1", "data": {"isActive": True, "alertSent": False, "ticker": "GUSM"}},
            {"id": "a2", "uid": "u2", "data": {"isActive": False, "alertSent": False, "ticker": "PSO"}},
            {"id": "a3", "uid": "u3", "data": {"isActive": True, "alertSent": True, "ticker": "PPL"}},
        ]
    )
    results = firestore_io.get_watched_alerts(db)
    tickers = {r["ticker"] for r in results}
    assert tickers == {"GUSM"}
