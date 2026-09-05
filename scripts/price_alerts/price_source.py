"""The swappable price-fetch seam.

PSX publishes no public developer API; psxdata scrapes the public site.
Behind a Protocol so the scraping dependency can be swapped or mocked
without touching main.py.
"""

from typing import Protocol

import pandas as pd
import psxdata


class PriceSource(Protocol):
    def fetch_prices(self, tickers: set[str]) -> dict[str, dict]: ...


class PsxdataScreenerSource:
    """Fetches all PSX prices in one request via psxdata's screener table.

    Deliberately not a per-ticker loop (`psxdata.quote()` per symbol) — the
    screener returns the whole board (~729 symbols) in one request; a
    per-ticker loop would be dozens of sequential scrapes per run, far more
    fragile and far heavier on PSX's servers for no benefit.
    """

    def fetch_prices(self, tickers: set[str]) -> dict[str, dict]:
        """Returns {ticker: {"price": float, "previousClose": float}} for
        every requested ticker actually present in the screener.

        Both fields are required — the Dart client's MarketPriceModel
        (Phase 04) parses `previousClose` with `(json['previousClose'] as
        num).toDouble()`, no null check, so a document missing it throws
        instead of just showing a placeholder. previousClose is derived
        from the screener's `change_pct` (price / (1 + change_pct/100));
        if that itself is unavailable, previousClose falls back to price
        (a safe "0% change" default) rather than omitting the ticker
        entirely over a field the app doesn't strictly need to be exact.

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
        result: dict[str, dict] = {}
        for _, row in matches.iterrows():
            price = row["price"]
            if pd.isna(price):
                continue
            price = float(price)

            change_pct = row.get("change_pct")
            if change_pct is not None and not pd.isna(change_pct) and change_pct != -100:
                previous_close = price / (1 + change_pct / 100)
            else:
                previous_close = price

            result[row["symbol"]] = {"price": price, "previousClose": previous_close}
        return result
