import json
from pathlib import Path
from unittest.mock import patch

import pandas as pd
import pytest

from price_source import PsxdataScreenerSource

FIXTURE_PATH = Path(__file__).parent / "fixtures" / "screener_sample.json"


def _load_screener_fixture() -> pd.DataFrame:
    with open(FIXTURE_PATH) as f:
        data = json.load(f)
    return pd.DataFrame(data["rows"])


def test_9_ticker_absent_from_screener_is_omitted_never_zero():
    """A real captured screener sample (5 known tickers) — request one that
    isn't in it. It must be entirely absent from the result, never present
    with a substituted 0.0."""
    with (
        patch("price_source.psxdata.screener", return_value=_load_screener_fixture()),
        # Patched so the fallback can't reach the real network — this suite
        # must run without any.
        patch("price_source.psxdata.stocks", return_value=pd.DataFrame()),
    ):
        source = PsxdataScreenerSource()
        prices = source.fetch_prices({"ENGRO", "NOT-A-REAL-TICKER"})

    assert "NOT-A-REAL-TICKER" not in prices
    assert prices["ENGRO"]["price"] == 485.38


def test_10_contract_vs_real_captured_screener_fixture():
    """This fixture is a real subset of psxdata.screener()'s live output
    (see fixtures/screener_sample.json's `_captured` note). If a future
    psxdata upgrade renames the 'symbol', 'price' or 'change_pct' columns,
    fetch_prices's column access breaks against this same fixture — failing
    here in CI, not silently in production.

    Every entry must carry both `price` and `previousClose` — the Dart
    client's MarketPriceModel requires both, with no null fallback for
    `previousClose` (see firestore_io.write_market_prices's docstring)."""
    with patch("price_source.psxdata.screener", return_value=_load_screener_fixture()):
        source = PsxdataScreenerSource()
        prices = source.fetch_prices({"ENGRO", "HUBC", "LUCK", "OGDC", "UBL"})

    assert prices.keys() == {"ENGRO", "HUBC", "LUCK", "OGDC", "UBL"}
    for ticker, (price, change_pct) in {
        "ENGRO": (485.38, 1.48),
        "HUBC": (207.44, 0.35),
        "LUCK": (433.12, 0.42),
        "OGDC": (328.8, 0.54),
        "UBL": (440.83, -0.54),
    }.items():
        assert prices[ticker]["price"] == price
        assert prices[ticker]["previousClose"] == pytest.approx(price / (1 + change_pct / 100))


def test_empty_screener_with_no_history_either_returns_empty_dict():
    """An empty screener no longer means "no prices" outright — it falls
    through to the history fallback. Only when that has nothing either does
    the ticker get omitted."""
    with (
        patch("price_source.psxdata.screener", return_value=pd.DataFrame()),
        patch("price_source.psxdata.stocks", return_value=pd.DataFrame()),
    ):
        source = PsxdataScreenerSource()
        assert source.fetch_prices({"ENGRO"}) == {}


def test_nan_price_is_omitted_not_treated_as_zero():
    """A NaN screener price falls through to the history fallback; with no
    history either, the ticker is omitted rather than priced at 0."""
    df = pd.DataFrame([{"symbol": "ENGRO", "price": float("nan"), "change_pct": 0.0}])
    with (
        patch("price_source.psxdata.screener", return_value=df),
        patch("price_source.psxdata.stocks", return_value=pd.DataFrame()),
    ):
        source = PsxdataScreenerSource()
        assert source.fetch_prices({"ENGRO"}) == {}


def _history(rows: list[dict]) -> pd.DataFrame:
    return pd.DataFrame(rows)


def test_ticker_absent_from_screener_falls_back_to_last_real_close():
    """PSX's screener isn't the full listed universe — ~120 actively-trading
    equities are missing from it (GUSM/Gulistan Spinning Mills traded 303k
    shares on a day it had no screener row). Those must still get a price
    from the historical endpoint rather than showing "—" forever."""
    history = _history([
        {"date": pd.Timestamp("2026-09-03"), "close": 10.78, "volume": 129091},
        {"date": pd.Timestamp("2026-09-04"), "close": 10.68, "volume": 303972},
    ])

    with (
        patch("price_source.psxdata.screener", return_value=_load_screener_fixture()),
        patch("price_source.psxdata.stocks", return_value=history) as mock_stocks,
    ):
        prices = PsxdataScreenerSource().fetch_prices({"ENGRO", "GUSM"})

    mock_stocks.assert_called_once_with("GUSM")
    assert prices["GUSM"] == {"price": 10.68, "previousClose": 10.78}
    # The screener path still serves everything it does cover.
    assert prices["ENGRO"]["price"] == 485.38


def test_history_fallback_ignores_zero_volume_placeholder_rows():
    """psxdata pads non-trading days with zero-volume rows whose OHLC is 0.0.
    Taking the last row blindly would invent a price of 0 — which would fire
    every buy alert watching that ticker at once."""
    history = _history([
        {"date": pd.Timestamp("2026-09-04"), "close": 10.68, "volume": 303972},
        {"date": pd.Timestamp("2026-09-05"), "close": 0.0, "volume": 0},
    ])

    with (
        patch("price_source.psxdata.screener", return_value=pd.DataFrame()),
        patch("price_source.psxdata.stocks", return_value=history),
    ):
        prices = PsxdataScreenerSource().fetch_prices({"GUSM"})

    assert prices["GUSM"]["price"] == 10.68


def test_history_fallback_sorts_by_date_before_taking_the_latest():
    """psxdata returns history unsorted and warns about it — relying on row
    order would pick a decade-old price."""
    history = _history([
        {"date": pd.Timestamp("2016-09-05"), "close": 1.40, "volume": 10},
        {"date": pd.Timestamp("2026-09-04"), "close": 10.68, "volume": 303972},
        {"date": pd.Timestamp("2020-01-02"), "close": 5.00, "volume": 20},
    ])

    with (
        patch("price_source.psxdata.screener", return_value=pd.DataFrame()),
        patch("price_source.psxdata.stocks", return_value=history),
    ):
        prices = PsxdataScreenerSource().fetch_prices({"GUSM"})

    assert prices["GUSM"]["price"] == 10.68


def test_history_fallback_failure_omits_the_ticker_without_aborting_the_run():
    """One unavailable ticker must not take down a run that has good prices
    for everything else."""
    with (
        patch("price_source.psxdata.screener", return_value=_load_screener_fixture()),
        patch("price_source.psxdata.stocks", side_effect=Exception("boom")),
    ):
        prices = PsxdataScreenerSource().fetch_prices({"ENGRO", "NOPE"})

    assert "NOPE" not in prices
    assert prices["ENGRO"]["price"] == 485.38


def test_a_ticker_that_never_traded_is_omitted_not_priced_at_zero():
    history = _history([
        {"date": pd.Timestamp("2026-09-04"), "close": 0.0, "volume": 0},
    ])

    with (
        patch("price_source.psxdata.screener", return_value=pd.DataFrame()),
        patch("price_source.psxdata.stocks", return_value=history),
    ):
        assert PsxdataScreenerSource().fetch_prices({"DEAD"}) == {}


def test_missing_change_pct_falls_back_to_previous_close_equals_price():
    """A row with a valid price but no usable change_pct must still produce
    a usable previousClose (== price, i.e. "0% change") rather than being
    omitted or crashing — the app needs previousClose to exist, not to be
    perfectly accurate."""
    df = pd.DataFrame([{"symbol": "ENGRO", "price": 100.0, "change_pct": float("nan")}])
    with patch("price_source.psxdata.screener", return_value=df):
        source = PsxdataScreenerSource()
        prices = source.fetch_prices({"ENGRO"})

    assert prices["ENGRO"] == {"price": 100.0, "previousClose": 100.0}
