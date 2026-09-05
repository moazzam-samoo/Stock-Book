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


def get_held_positions(db) -> list[dict]:
    """Every position that still holds shares (open or partiallySold — a
    partial sale still has shares held and can still carry a live
    targetPrice, see PHASE-03C), across all users.

    Returns plain dicts with `uid` and `id` merged in alongside the position
    fields, since the caller needs both to write back a fired alert.
    """
    query = db.collection_group("positions").where("status", "in", ["open", "partiallySold"])
    results = []
    for doc in query.stream():
        data = doc.to_dict()
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


def write_market_prices(db, prices: dict[str, float]) -> None:
    batch = db.batch()
    for ticker, price in prices.items():
        ref = db.collection("market_prices").document(ticker)
        batch.set(ref, {"price": price, "checkedAt": firestore.SERVER_TIMESTAMP})
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
