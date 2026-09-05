import json
from pathlib import Path
from unittest.mock import patch

import pandas as pd

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
    with patch("price_source.psxdata.screener", return_value=_load_screener_fixture()):
        source = PsxdataScreenerSource()
        prices = source.fetch_prices({"ENGRO", "NOT-A-REAL-TICKER"})

    assert "NOT-A-REAL-TICKER" not in prices
    assert prices["ENGRO"] == 485.38


def test_10_contract_vs_real_captured_screener_fixture():
    """This fixture is a real subset of psxdata.screener()'s live output
    (see fixtures/screener_sample.json's `_captured` note). If a future
    psxdata upgrade renames the 'symbol' or 'price' columns, fetch_prices's
    column access breaks against this same fixture — failing here in CI,
    not silently in production."""
    with patch("price_source.psxdata.screener", return_value=_load_screener_fixture()):
        source = PsxdataScreenerSource()
        prices = source.fetch_prices({"ENGRO", "HUBC", "LUCK", "OGDC", "UBL"})

    assert prices == {
        "ENGRO": 485.38,
        "HUBC": 207.44,
        "LUCK": 433.12,
        "OGDC": 328.8,
        "UBL": 440.83,
    }


def test_empty_screener_returns_empty_dict():
    with patch("price_source.psxdata.screener", return_value=pd.DataFrame()):
        source = PsxdataScreenerSource()
        assert source.fetch_prices({"ENGRO"}) == {}


def test_nan_price_is_omitted_not_treated_as_zero():
    df = pd.DataFrame([{"symbol": "ENGRO", "price": float("nan")}])
    with patch("price_source.psxdata.screener", return_value=df):
        source = PsxdataScreenerSource()
        assert source.fetch_prices({"ENGRO"}) == {}
