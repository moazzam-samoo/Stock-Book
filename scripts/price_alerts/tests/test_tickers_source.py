import json
from pathlib import Path
from unittest.mock import patch

import pandas as pd

from tickers_source import fetch_listed_companies

FIXTURE_PATH = Path(__file__).parent / "fixtures" / "symbols_sample.json"


def _load_symbols_fixture() -> pd.DataFrame:
    with open(FIXTURE_PATH) as f:
        data = json.load(f)
    return pd.DataFrame(data["rows"])


def test_16_returns_symbol_and_name_for_every_row():
    """Real captured psxdata.symbols() sample — see fixtures/symbols_sample.json."""
    with patch("tickers_source.psxdata.symbols", return_value=_load_symbols_fixture()):
        companies = fetch_listed_companies()

    assert len(companies) == 5
    engro = next(c for c in companies if c["symbol"] == "ENGRO")
    assert engro["name"] == "Engro Corporation Limited"
    assert engro["sector"] == "FERTILIZER"


def test_empty_symbols_returns_empty_list():
    with patch("tickers_source.psxdata.symbols", return_value=pd.DataFrame()):
        assert fetch_listed_companies() == []
