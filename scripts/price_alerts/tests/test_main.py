from unittest.mock import Mock, patch

from fakes import FakeDb
from psxdata.exceptions import PSXDataError

import main


def test_8_missing_fcm_token_is_skipped_not_an_exception():
    db = object()  # firestore_io calls are all mocked below; db is never touched
    positions = [
        {"id": "p1", "uid": "u1", "ticker": "ENGRO", "targetPrice": 100.0, "targetAlertSent": False}
    ]
    prices = {"ENGRO": {"price": 150.0, "previousClose": 148.0}}

    with (
        patch("main.firestore_io.get_fcm_token", return_value=None) as mock_get_token,
        patch("main.firestore_io.send_push") as mock_send,
        patch("main.firestore_io.mark_sell_alert_sent") as mock_mark,
    ):
        main._run_sell_alerts_step(db, positions, prices)  # must not raise

    mock_get_token.assert_called_once_with(db, "u1")
    mock_send.assert_not_called()
    mock_mark.assert_not_called()


def test_15a_price_fetch_failure_does_not_block_market_status_write():
    db = FakeDb(positions=[{"id": "p1", "uid": "u1", "data": {"status": "open", "ticker": "ENGRO"}}])
    fake_price_source = Mock()
    fake_price_source.fetch_prices.side_effect = PSXDataError("scrape failed")

    with (
        patch("main.fetch_market_status", return_value={"isOpen": True, "label": "Open"}),
        patch("main.firestore_io.get_current_market_status", return_value=None),
        patch("main.firestore_io.write_market_status") as mock_write_status,
        patch("main.firestore_io.write_market_prices") as mock_write_prices,
        patch("main.fetch_listed_companies", return_value=[]),
    ):
        main.run(db, price_source=fake_price_source)

    mock_write_status.assert_called_once()
    mock_write_prices.assert_not_called()


def test_15b_market_status_failure_does_not_block_price_dependent_steps():
    db = FakeDb(
        positions=[
            {
                "id": "p1",
                "uid": "u1",
                "data": {"status": "open", "ticker": "ENGRO", "targetPrice": None, "targetAlertSent": False},
            }
        ]
    )
    fake_price_source = Mock()
    fake_price_source.fetch_prices.return_value = {"ENGRO": {"price": 150.0, "previousClose": 148.0}}

    with (
        patch("main.fetch_market_status", side_effect=Exception("homepage layout changed")),
        patch("main.firestore_io.write_market_status") as mock_write_status,
        patch("main.firestore_io.write_market_prices") as mock_write_prices,
        patch("main.fetch_listed_companies", return_value=[]),
    ):
        main.run(db, price_source=fake_price_source)

    mock_write_status.assert_not_called()
    mock_write_prices.assert_called_once_with(db, {"ENGRO": {"price": 150.0, "previousClose": 148.0}})


def test_market_status_transition_pushes_to_every_known_token():
    """A closed->open (or open->closed) flip is the one thing that should
    broadcast to every signed-in user, not just whoever holds a position or
    watches an alert on a specific ticker."""
    db = object()  # every firestore_io call is mocked below

    with (
        patch("main.fetch_market_status", return_value={"isOpen": True, "label": "Open"}),
        patch(
            "main.firestore_io.get_current_market_status",
            return_value={"isOpen": False, "label": "Closed"},
        ),
        patch("main.firestore_io.write_market_status") as mock_write_status,
        patch("main.firestore_io.get_all_fcm_tokens", return_value=["tok1", "tok2"]),
        patch("main.firestore_io.send_push") as mock_send,
    ):
        main._run_market_status_step(db)

    mock_write_status.assert_called_once_with(db, {"isOpen": True, "label": "Open"})
    assert mock_send.call_count == 2
    mock_send.assert_any_call("tok1", {"type": "market_open"})
    mock_send.assert_any_call("tok2", {"type": "market_open"})


def test_market_status_unchanged_sends_no_push():
    db = object()

    with (
        patch("main.fetch_market_status", return_value={"isOpen": True, "label": "Open"}),
        patch(
            "main.firestore_io.get_current_market_status",
            return_value={"isOpen": True, "label": "Open"},
        ),
        patch("main.firestore_io.write_market_status"),
        patch("main.firestore_io.get_all_fcm_tokens") as mock_get_tokens,
        patch("main.firestore_io.send_push") as mock_send,
    ):
        main._run_market_status_step(db)

    mock_get_tokens.assert_not_called()
    mock_send.assert_not_called()


def test_market_status_first_ever_run_sends_no_push():
    """No previous doc (previous is None) must never be treated as "was
    closed" — that would fire a spurious market-open push the very first
    time this ever runs during market hours."""
    db = object()

    with (
        patch("main.fetch_market_status", return_value={"isOpen": True, "label": "Open"}),
        patch("main.firestore_io.get_current_market_status", return_value=None),
        patch("main.firestore_io.write_market_status"),
        patch("main.firestore_io.get_all_fcm_tokens") as mock_get_tokens,
        patch("main.firestore_io.send_push") as mock_send,
    ):
        main._run_market_status_step(db)

    mock_get_tokens.assert_not_called()
    mock_send.assert_not_called()


def test_market_status_one_bad_token_does_not_stop_the_rest():
    db = object()

    with (
        patch("main.fetch_market_status", return_value={"isOpen": False, "label": "Closed"}),
        patch(
            "main.firestore_io.get_current_market_status",
            return_value={"isOpen": True, "label": "Open"},
        ),
        patch("main.firestore_io.write_market_status"),
        patch("main.firestore_io.get_all_fcm_tokens", return_value=["bad", "good"]),
        patch("main.firestore_io.send_push", side_effect=[Exception("unregistered"), None]) as mock_send,
    ):
        main._run_market_status_step(db)  # must not raise

    assert mock_send.call_count == 2


def test_stored_ticker_whitespace_is_normalised_before_the_price_lookup():
    """A position saved with a stray trailing space ("BNL ") must still get
    a price — PSX's screener only knows the clean symbol, so an
    unnormalised lookup silently matches nothing and that holding shows "—"
    forever. Mirrors the Dart client's FirestoreDataSource.normalizeTicker."""
    db = FakeDb(
        positions=[{"id": "p1", "uid": "u1", "data": {"status": "open", "ticker": "bnl "}}]
    )
    fake_price_source = Mock()
    fake_price_source.fetch_prices.return_value = {}

    with (
        patch("main.fetch_market_status", return_value=None),
        patch("main.firestore_io.write_market_prices"),
        patch("main.fetch_listed_companies", return_value=[]),
    ):
        main.run(db, price_source=fake_price_source)

    fake_price_source.fetch_prices.assert_called_once_with({"BNL"})


def test_17_tickers_doc_only_written_when_content_changed():
    db = object()
    companies = [{"symbol": "ENGRO", "name": "Engro Corporation Limited", "sector": "FERTILIZER"}]

    with (
        patch("main.fetch_listed_companies", return_value=companies),
        patch("main.firestore_io.get_tickers_doc", return_value={"companies": companies}),
        patch("main.firestore_io.write_tickers_doc") as mock_write,
    ):
        main._run_tickers_refresh_step(db)

    mock_write.assert_not_called()


def test_17b_tickers_doc_is_written_when_content_differs():
    db = object()
    old_companies = [{"symbol": "ENGRO", "name": "Engro Corporation Limited", "sector": "FERTILIZER"}]
    new_companies = old_companies + [{"symbol": "LUCK", "name": "Lucky Cement Limited", "sector": "CEMENT"}]

    with (
        patch("main.fetch_listed_companies", return_value=new_companies),
        patch("main.firestore_io.get_tickers_doc", return_value={"companies": old_companies}),
        patch("main.firestore_io.write_tickers_doc") as mock_write,
    ):
        main._run_tickers_refresh_step(db)

    mock_write.assert_called_once_with(db, new_companies)
