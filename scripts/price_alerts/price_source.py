"""The swappable price-fetch seam.

PSX publishes no public developer API; psxdata scrapes the public site.
Behind a Protocol so the scraping dependency can be swapped or mocked
without touching main.py.
"""

import re
import time
from typing import Protocol

import pandas as pd
import psxdata
import requests
from bs4 import BeautifulSoup

# Same browser-like headers psxdata itself sends; PSX rejects bare clients.
_COMPANY_PAGE_URL = "https://dps.psx.com.pk/company/{symbol}"
_COMPANY_PAGE_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36"
    ),
    "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
    "Referer": "https://dps.psx.com.pk/",
}
_COMPANY_PAGE_TIMEOUT = 20  # seconds

_NUMBER = re.compile(r"-?\d[\d,]*\.?\d*")


def _first_number(text: str) -> float | None:
    match = _NUMBER.search(text.replace("−", "-"))
    if not match:
        return None
    try:
        return float(match.group(0).replace(",", ""))
    except ValueError:
        return None


def parse_company_quote(html: str) -> dict | None:
    """Current price + previous close from a PSX `/company/<SYM>` page.

    The header block carries `.quote__close` ("Rs.8.80" — the live price
    while the market is open, the official close after it) and
    `.quote__change` ("0.33 (3.90%)", absolute change vs the previous
    close). previousClose is derived as price - change; it is *not* read
    from an "LDCP" stat because that label appears once per market segment
    on the page, which is ambiguous.

    Returns None (never a zero or guessed price) if the quote block is
    missing or unparseable — the caller then moves on to the next source.
    """
    soup = BeautifulSoup(html, "html.parser")
    close_el = soup.select_one(".quote__close")
    if close_el is None:
        return None
    price = _first_number(close_el.get_text(" ", strip=True))
    if price is None or price <= 0:
        return None

    change_el = soup.select_one(".quote__change")
    change = _first_number(change_el.get_text(" ", strip=True)) if change_el else None
    previous_close = price - change if change is not None else price
    if previous_close <= 0:
        previous_close = price
    return {"price": price, "previousClose": previous_close}


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
        watching it.

        A hard failure of the bulk screener call itself (network error, PSX
        briefly down, rate-limited — anything `psxdata.screener()` itself
        raises) is caught here and treated the same as an unusable/empty
        response, rather than aborting the whole function: it must not take
        every ticker down with it when many of them could still be fetched
        individually via the per-ticker fallback below. This was a real,
        confirmed bug — two different tickers went stale for two consecutive
        runs at the exact same timestamp, which only makes sense if a single
        bulk-call failure had silently skipped every ticker that run, not
        just one.
        """
        try:
            df = psxdata.screener()
        except Exception:  # noqa: BLE001 — see docstring: must not abort the per-ticker fallback below
            df = pd.DataFrame()

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
        #
        # Order matters: the company page first, history second. PSX started
        # answering 403 on /historical (and /timeseries/*) while the HTML
        # company page kept working, so history alone left every
        # screener-absent ticker frozen at its last successful run.
        for ticker in sorted(tickers - result.keys()):
            entry = self._fetch_from_company_page(ticker)
            if entry is None:
                entry = self._fetch_from_history(ticker)
            if entry is not None:
                result[ticker] = entry

        return result

    def _fetch_from_company_page(self, ticker: str, *, retries: int = 1) -> dict | None:
        """Live price for a ticker from PSX's HTML company page, or None.

        Never raises: one unavailable ticker must not abort the run.
        """
        for attempt in range(retries + 1):
            try:
                resp = requests.get(
                    _COMPANY_PAGE_URL.format(symbol=ticker),
                    headers=_COMPANY_PAGE_HEADERS,
                    timeout=_COMPANY_PAGE_TIMEOUT,
                )
                if resp.status_code == 200:
                    return parse_company_quote(resp.text)
                if resp.status_code in (401, 403, 404):
                    return None  # blocked / unknown symbol: retrying won't help
            except requests.RequestException:
                pass
            if attempt < retries:
                time.sleep(1)
        return None

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
