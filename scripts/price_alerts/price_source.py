"""The swappable price-fetch seam.

PSX publishes no public developer API; psxdata scrapes the public site.
Behind a Protocol so the scraping dependency can be swapped or mocked
without touching main.py.
"""

from typing import Protocol

import pandas as pd
import psxdata


class PriceSource(Protocol):
    def fetch_prices(self, tickers: set[str]) -> dict[str, float]: ...


class PsxdataScreenerSource:
    """Fetches all PSX prices in one request via psxdata's screener table.

    Deliberately not a per-ticker loop (`psxdata.quote()` per symbol) — the
    screener returns the whole board (~729 symbols) in one request; a
    per-ticker loop would be dozens of sequential scrapes per run, far more
    fragile and far heavier on PSX's servers for no benefit.
    """

    def fetch_prices(self, tickers: set[str]) -> dict[str, float]:
        """Returns {ticker: price} for every requested ticker actually
        present in the screener.

        A ticker missing from the screener is omitted entirely — never
        substituted with 0, which would falsely fire every buy alert
        watching it. Raises `psxdata.exceptions.PSXDataError` (or a
        subclass) on a scrape failure; the caller must treat that as "abort
        this run's price-dependent steps," not swallow it here — a silently
        empty dict is indistinguishable from "nothing matched," which is a
        different, valid case.
        """
        df = psxdata.screener()

        if df.empty or "symbol" not in df.columns or "price" not in df.columns:
            return {}

        matches = df[df["symbol"].isin(tickers)]
        prices: dict[str, float] = {}
        for _, row in matches.iterrows():
            price = row["price"]
            if pd.isna(price):
                continue
            prices[row["symbol"]] = float(price)
        return prices
