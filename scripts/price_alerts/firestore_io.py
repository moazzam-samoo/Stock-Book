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
    """Every active, not-yet-sent buy alert, across all users."""
    query = (
        db.collection_group("price_alerts")
        .where("isActive", "==", True)
        .where("alertSent", "==", False)
    )
    results = []
    for doc in query.stream():
        data = doc.to_dict()
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


def send_push(token: str, data: dict) -> None:
    """`data` values must all be strings — a float or None fails at send
    time on the FCM side, so callers must stringify before calling this."""
    message = messaging.Message(data=data, token=token)
    messaging.send(message)


def mark_sell_alert_sent(db, uid: str, position_id: str) -> None:
    ref = db.collection("users").document(uid).collection("positions").document(position_id)
    ref.update(
        {
            "targetAlertSent": True,
            "targetAlertSentAt": firestore.SERVER_TIMESTAMP,
        }
    )


def mark_buy_alert_sent(db, uid: str, alert_id: str) -> None:
    ref = db.collection("users").document(uid).collection("price_alerts").document(alert_id)
    ref.update(
        {
            "alertSent": True,
            "isActive": False,
            "alertSentAt": firestore.SERVER_TIMESTAMP,
        }
    )
