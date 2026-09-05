"""Fetches the full PSX ticker reference list (symbol + company name).

Confirmed against psxdata==1.1.0's source directly: `screener()` has no
company-name column (only symbol, sector code, and price/volume fields —
its docstring says as much), but the library ships a dedicated `symbols()`
function that returns exactly what's needed: symbol, name, sector_name.
That's a separate PSX endpoint (/symbols, JSON) from screener's (/screener,
HTML table), so this has its own try/except, same reasoning as
market_status_source.py being independent of price_source.py.
"""

import psxdata


def fetch_listed_companies() -> list[dict]:
    """Returns [{"symbol": ..., "name": ..., "sector": ...}, ...] for every
    PSX-listed instrument. Raises `psxdata.exceptions.PSXDataError` (or a
    subclass) on failure — the caller decides whether to skip this run's
    write, same pattern as price_source.py.
    """
    df = psxdata.symbols()

    if df.empty or "symbol" not in df.columns or "name" not in df.columns:
        return []

    companies = []
    for _, row in df.iterrows():
        companies.append(
            {
                "symbol": row["symbol"],
                "name": row["name"],
                "sector": row.get("sector_name"),
            }
        )
    return companies
