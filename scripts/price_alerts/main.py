"""Orchestration only — no business logic lives here.

Runs once per invocation (GitHub Actions cron or workflow_dispatch):
1. Find every ticker currently held or watched.
2. Fetch their live prices in one request.
3. Write market_prices/ and market_status/current.
4. Decide which sell/buy alerts fire (alerts.py, pure) and send them.
5. Refresh the tickers/all reference list, at most once a day.
"""

import os
import sys

from psxdata.exceptions import PSXDataError

import alerts
import firestore_io
from price_source import PsxdataScreenerSource
from market_status_source import fetch_market_status
from tickers_source import fetch_listed_companies


def _normalize_ticker(ticker) -> str:
    """Mirrors the Dart client's FirestoreDataSource.normalizeTicker — both
    sides must agree, or the backend writes market_prices/BNL while the app
    looks up market_prices/'BNL ' and finds nothing."""
    if not isinstance(ticker, str):
        return ""
    return ticker.strip().upper()


def run(db, price_source=None) -> None:
    price_source = price_source or PsxdataScreenerSource()

    positions = firestore_io.get_held_positions(db)
    watched_alerts = firestore_io.get_watched_alerts(db)

    # Logged with repr() deliberately: stray whitespace and case are exactly
    # the failure modes that have bitten here, and both are invisible in
    # plain output. This is an unattended cron job — a run log that doesn't
    # say what it actually saw makes every failure a guessing game.
    print(f"Found {len(positions)} held position(s), {len(watched_alerts)} active alert(s)")
    print(f"  raw position tickers: {[(p.get('ticker'), p.get('status')) for p in positions]!r}")
    print(f"  raw alert tickers:    {[a.get('ticker') for a in watched_alerts]!r}")

    # A stored ticker can carry stray whitespace or lowercase from the app's
    # free-text ticker entry (it has never been strictly validated). PSX's
    # screener only ever knows the clean symbol, so an unnormalised "BNL "
    # matches nothing and that holding silently never gets a price at all.
    for p in positions:
        p["ticker"] = _normalize_ticker(p.get("ticker"))
    for a in watched_alerts:
        a["ticker"] = _normalize_ticker(a.get("ticker"))

    held_tickers = {p["ticker"] for p in positions if p["ticker"]}
    watched_tickers = {a["ticker"] for a in watched_alerts if a["ticker"]}
    all_tickers = held_tickers | watched_tickers
    print(f"  requesting prices for: {sorted(all_tickers)!r}")

    prices: dict[str, dict] = {}
    try:
        if all_tickers:
            prices = price_source.fetch_prices(all_tickers)
    except PSXDataError as e:
        # A scrape failure aborts price-dependent steps for this run only —
        # it must not crash the process, since market status and the
        # tickers list are independent and should still be attempted.
        print(f"Price fetch failed, skipping price-dependent steps this run: {e}", file=sys.stderr)
        prices = {}

    missing = sorted(all_tickers - prices.keys())
    print(f"  got prices for: {sorted(prices)!r}")
    if missing:
        # Not an error: a ticker with no price anywhere (not in the screener
        # and never traded per the historical endpoint) is deliberately
        # omitted rather than written as 0. But it IS the thing to look at
        # first when a holding shows no live price in the app.
        print(f"  NO price available anywhere on PSX: {missing!r}")

    if prices:
        firestore_io.write_market_prices(db, prices)

    _run_market_status_step(db)
    _run_sell_alerts_step(db, positions, prices)
    _run_buy_alerts_step(db, watched_alerts, prices)
    _run_tickers_refresh_step(db)


def _run_market_status_step(db) -> None:
    try:
        status = fetch_market_status()
    except Exception as e:  # noqa: BLE001 — any homepage-scrape failure must not propagate
        print(f"Market status fetch failed, skipping this run: {e}", file=sys.stderr)
        return

    if status is not None:
        firestore_io.write_market_status(db, status)


def _run_sell_alerts_step(db, positions: list[dict], prices: dict[str, dict]) -> None:
    for position in positions:
        ticker = position.get("ticker")
        entry = prices.get(ticker)
        if entry is None:
            continue
        price = entry["price"]
        if not alerts.should_fire_sell(position, price):
            continue

        uid = position["uid"]
        token = firestore_io.get_fcm_token(db, uid)
        if token is None:
            continue  # no fcmToken means the user hasn't granted permission — not an error

        firestore_io.send_push(
            token,
            {"type": "sell", "ticker": ticker, "positionId": position["id"]},
        )
        # Push first, then flip the flag — a flag write failing after a
        # successful send means at most one duplicate notification; the
        # reverse order can silently tell nobody at all.
        firestore_io.mark_sell_alert_sent(db, uid, position["id"])


def _run_buy_alerts_step(db, watched_alerts: list[dict], prices: dict[str, dict]) -> None:
    for alert in watched_alerts:
        ticker = alert.get("ticker")
        entry = prices.get(ticker)
        if entry is None:
            continue
        price = entry["price"]
        if not alerts.should_fire_buy(alert, price):
            continue

        uid = alert["uid"]
        token = firestore_io.get_fcm_token(db, uid)
        if token is None:
            continue

        firestore_io.send_push(
            token,
            {"type": "buy", "ticker": ticker, "alertId": alert["id"]},
        )
        firestore_io.mark_buy_alert_sent(db, uid, alert["id"])


def _run_tickers_refresh_step(db) -> None:
    try:
        companies = fetch_listed_companies()
    except Exception as e:  # noqa: BLE001 — a /symbols failure must not propagate
        print(f"Tickers list fetch failed, skipping this run: {e}", file=sys.stderr)
        return

    if not companies:
        return

    existing = firestore_io.get_tickers_doc(db)
    if existing is not None and existing.get("companies") == companies:
        return  # unchanged — avoid a pointless write every 15 minutes

    firestore_io.write_tickers_doc(db, companies)


if __name__ == "__main__":
    service_account_path = os.environ["FIREBASE_SERVICE_ACCOUNT_PATH"]
    firestore_db = firestore_io.init_firestore(service_account_path)
    run(firestore_db)
