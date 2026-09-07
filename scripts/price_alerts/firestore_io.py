"""All Firestore reads/writes for the price-alerts backend.

Kept separate from alerts.py (pure decision logic) and main.py
(orchestration) so the network/Firebase boundary is in exactly one place.
"""

import firebase_admin
from firebase_admin import credentials, firestore, messaging


def init_firestore(service_account_path: str):
    """Initialise the Admin SDK from a service account JSON file and return
    a Firestore client. Safe to call once per process."""
    if not firebase_admin._apps:
        cred = credentials.Certificate(service_account_path)
        firebase_admin.initialize_app(cred)
    return firestore.client()


def is_still_held(status) -> bool:
    """"Still holding" is defined as *not closed*, deliberately — the same
    way the Dart client defines it (`filteredPositions`: `status !=
    PositionStatus.closed`), including its treatment of an unrecognised
    value.

    This must not be an `in ["open", "partiallySold"]` allow-list. The
    client's `PositionModel.toEntity()` maps any unrecognised status string
    to `open` via its `default:` branch, so a position carrying a legacy or
    oddly-cased status displays as OPEN in the app while an allow-list query
    silently skips it — the holding then never gets a price and its sell
    alert can never fire, with nothing visibly wrong anywhere. Mirroring the
    client's own definition keeps the two sides from disagreeing.
    """
    if not isinstance(status, str):
        return True  # missing/malformed status: the client shows it, so do we
    return status.strip().lower() != "closed"


def get_held_positions(db) -> list[dict]:
    """Every position that still holds shares (anything not closed — a
    partial sale still has shares held and can still carry a live
    targetPrice, see PHASE-03C), across all users.

    Filtered in Python rather than by a Firestore `where` clause so the
    "not closed" rule above stays authoritative; the position count per user
    is tiny, so the read cost is irrelevant.

    Returns plain dicts with `uid` and `id` merged in alongside the position
    fields, since the caller needs both to write back a fired alert.
    """
    query = db.collection_group("positions")
    results = []
    for doc in query.stream():
        data = doc.to_dict()
        if not is_still_held(data.get("status")):
            continue
        data["id"] = doc.id
        data["uid"] = doc.reference.parent.parent.id
        results.append(data)
    return results


def get_watched_alerts(db) -> list[dict]:
    """Every active buy alert, across all users.

    No longer filters `alertSent == False` at the query level — alerts are
    not one-shot, so an alert that has already fired must stay watched for a
    further drop (alerts.py's should_fire_buy is what actually decides
    whether *this* run fires again). Filtering only `isActive` in Python
    (rather than a Firestore `where`) mirrors get_held_positions' same
    reasoning: per-user alert counts are tiny, so reading them all is free,
    and it keeps this one rule authoritative in one place instead of split
    between a query clause and this function's docstring.
    """
    query = db.collection_group("price_alerts")
    results = []
    for doc in query.stream():
        data = doc.to_dict()
        if not data.get("isActive", False):
            continue
        data["id"] = doc.id
        data["uid"] = doc.reference.parent.parent.id
        results.append(data)
    return results


def write_market_prices(db, prices: dict[str, dict]) -> None:
    """`prices` values must have `price` and `previousClose` keys — this is
    the exact field shape the Dart client's MarketPriceModel.fromJson
    requires (`ticker`, `price`, `previousClose`, `updatedAt`), including
    the `updatedAt` field name (not `checkedAt`); a document missing any of
    these throws in the app rather than just showing a placeholder.
    """
    batch = db.batch()
    for ticker, values in prices.items():
        ref = db.collection("market_prices").document(ticker)
        batch.set(
            ref,
            {
                "ticker": ticker,
                "price": values["price"],
                "previousClose": values["previousClose"],
                "updatedAt": firestore.SERVER_TIMESTAMP,
            },
        )
    if prices:
        batch.commit()


def get_current_market_status(db) -> dict | None:
    """The market_status doc as it stood *before* this run's write — read
    this first if you need to detect a transition, since write_market_status
    below overwrites it unconditionally. None means no doc exists yet (the
    very first run ever); callers must treat that as "no known previous
    state", never as "was closed"."""
    snap = db.collection("market_status").document("current").get()
    return snap.to_dict() if snap.exists else None


def write_market_status(db, status: dict) -> None:
    ref = db.collection("market_status").document("current")
    ref.set(
        {
            "isOpen": status["isOpen"],
            "label": status["label"],
            "checkedAt": firestore.SERVER_TIMESTAMP,
        }
    )


def get_tickers_doc(db) -> dict | None:
    snap = db.collection("tickers").document("all").get()
    return snap.to_dict() if snap.exists else None


def write_tickers_doc(db, companies: list[dict]) -> None:
    ref = db.collection("tickers").document("all")
    ref.set({"companies": companies, "updatedAt": firestore.SERVER_TIMESTAMP})


def get_fcm_token(db, uid: str) -> str | None:
    snap = db.collection("users").document(uid).get()
    if not snap.exists:
        return None
    return snap.to_dict().get("fcmToken")


def get_all_fcm_tokens(db) -> list[str]:
    """Every signed-in user's token, for a broadcast that isn't tied to any
    one user's positions/alerts (market open/close, unlike every other push
    this backend sends). A user who never granted notification permission
    (or hasn't opened the app since) simply has no fcmToken field and is
    skipped, same as get_fcm_token's None case elsewhere."""
    tokens = []
    for snap in db.collection("users").stream():
        token = snap.to_dict().get("fcmToken")
        if token:
            tokens.append(token)
    return tokens


def send_push(token: str, data: dict) -> None:
    """`data` values must all be strings — a float or None fails at send
    time on the FCM side, so callers must stringify before calling this.

    Explicit high Android priority: FCM's default for a data-only message
    (this app never sends a `notification` field — see
    push_notification_service.dart's payload-contract doc comment) is
    "normal", and Firebase's own docs warn normal-priority messages "may be
    delayed significantly" — the server can queue/batch them rather than
    deliver immediately, independent of the receiving device's own battery
    or Doze settings entirely. This was confirmed as a real, live bug: a
    push accepted without error by messaging.send() (no exception, nothing
    for the caller to catch) simply never reached a real device, in both
    foreground and background app states, until this was set.
    """
    message = messaging.Message(
        data=data,
        token=token,
        android=messaging.AndroidConfig(priority="high"),
    )
    messaging.send(message)


def mark_sell_alert_sent(db, uid: str, position_id: str, price: float) -> None:
    """`price` becomes `lastAlertPrice` — the baseline the *next* repeat fire
    is measured against (alerts.py's REPEAT_ALERT_STEP_PERCENT), not just a
    record of what happened this time."""
    ref = db.collection("users").document(uid).collection("positions").document(position_id)
    ref.update(
        {
            "targetAlertSent": True,
            "targetAlertSentAt": firestore.SERVER_TIMESTAMP,
            "lastAlertPrice": price,
        }
    )


def mark_buy_alert_sent(db, uid: str, alert_id: str, price: float) -> None:
    """Deliberately does NOT set isActive: False — a buy alert stays live so
    it can keep re-firing on a continued further drop; only editing the
    alert's target/tolerance (the client's PriceAlert.copyWith re-arm rule)
    or deleting it ends the alert now."""
    ref = db.collection("users").document(uid).collection("price_alerts").document(alert_id)
    ref.update(
        {
            "alertSent": True,
            "alertSentAt": firestore.SERVER_TIMESTAMP,
            "lastAlertPrice": price,
        }
    )
