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
