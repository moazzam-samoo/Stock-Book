"""The swappable price-fetch seam.

PSX publishes no public developer API; psxdata scrapes the public site.
Behind a Protocol so the scraping dependency can be swapped or mocked
without touching main.py.
"""

import time
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

        A ticker with no price anywhere is omitted entirely — never
        substituted with 0, which would falsely fire every buy alert
        watching it. Raises `psxdata.exceptions.PSXDataError` (or a
        subclass) on a screener failure; the caller must treat that as "abort
        this run's price-dependent steps," not swallow it here — a silently
        empty dict is indistinguishable from "nothing matched," which is a
        different, valid case.
        """
        df = psxdata.screener()

        result: dict[str, dict] = {}

        # An unusable screener response must not short-circuit the per-ticker
        # fallback below — that early return was itself a bug: it meant a
        # temporarily empty screener produced no prices at all, even for
        # tickers whose history was perfectly available.
        usable = not df.empty and "symbol" in df.columns and "price" in df.columns
        matches = df[df["symbol"].isin(tickers)] if usable else df.iloc[0:0]

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

        # PSX's screener is NOT the full listed universe: ~120 plain equities
        # (plus debt instruments and ETFs) are actively listed and trading but
        # simply absent from that table — GUSM/Gulistan Spinning Mills, for one,
        # traded 303k shares the day this was written while having no screener
        # row at all. Treating "absent from the screener" as "no price exists"
        # left such a holding showing "—" forever, looking like a bug in the app.
        #
        # For just those stragglers, fall back to the historical endpoint and
        # use the most recent real close. One extra request per missing ticker,
        # and only for tickers the single screener call didn't already cover.
        for ticker in sorted(tickers - result.keys()):
            entry = self._fetch_from_history(ticker)
            if entry is not None:
                result[ticker] = entry

        return result

    def _fetch_from_history(self, ticker: str, *, retries: int = 1) -> dict | None:
        """Most recent real close for a ticker, or None if it has never traded.

        Returns None rather than raising: a single unavailable ticker must not
        abort a run that has good prices for everything else.

        Retries once (with a short pause) before giving up. This is the path
        every screener-absent ticker (see `fetch_prices`) goes through on
        *every single run* — one extra scrape per ticker, per run — so a
        purely transient hiccup here (not "this ticker doesn't exist," just
        "that one request didn't land") used to skip the ticker for the
        entire run, leaving its Firestore doc's `updatedAt` stuck on
        whichever earlier run last succeeded. A stock that already goes
        through this fallback path every run is more exposed to exactly this
        kind of one-off failure than one covered by the single bulk screener
        call, so it's worth the extra request to not lose a run over it.
        """
        df = None
        for attempt in range(retries + 1):
            try:
                df = psxdata.stocks(ticker)
                break
            except Exception:  # noqa: BLE001 — one bad ticker can't take down the run
                if attempt == retries:
                    return None
                time.sleep(1)

        if df.empty or "date" not in df.columns or "close" not in df.columns:
            return None

        # psxdata returns history unsorted, and pads non-trading days with
        # zero-volume placeholder rows whose OHLC is 0.0 — taking the last row
        # blindly would yield a fabricated price. Only rows that actually
        # traded count.
        traded = df[df["volume"] > 0].sort_values("date") if "volume" in df.columns else df.sort_values("date")
        if traded.empty:
            return None

        last_close = traded.iloc[-1]["close"]
        if pd.isna(last_close):
            return None

        # The prior session's close is a real previousClose here, rather than
        # the screener path's derivation from change_pct.
        prev_close = traded.iloc[-2]["close"] if len(traded) > 1 else last_close
        if pd.isna(prev_close):
            prev_close = last_close

        return {"price": float(last_close), "previousClose": float(prev_close)}
