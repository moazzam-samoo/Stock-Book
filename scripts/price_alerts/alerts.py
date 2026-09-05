"""Pure decision logic for sell- and buy-target alerts.

No Firebase or network imports here, deliberately — every function takes
plain dicts and returns a plain decision, so this module is unit-testable
without credentials and without touching the network.
"""


def should_fire_sell(position: dict, price: float) -> bool:
    """A sell alert fires once a position's live price reaches its target.

    Mirrors the Dart app's PositionCalculator re-arm rule (Phase 06):
    targetPrice must be set, the alert must not already have been sent, and
    the price must be at or above the target.
    """
    target_price = position.get("targetPrice")
    if target_price is None:
        return False
    if position.get("targetAlertSent", False):
        return False
    return price >= target_price


def should_fire_buy(alert: dict, price: float) -> bool:
    """A buy alert fires once price drops to or within tolerance of target.

    Threshold: price <= targetPrice * (1 + tolerancePercent / 100).
    This must match Phase 07's `alertThreshold()`/`isAlertTriggered()` (Dart)
    exactly, including boundary behaviour: exactly at the threshold fires.
    """
    if not alert.get("isActive", False):
        return False
    if alert.get("alertSent", False):
        return False

    target_price = alert["targetPrice"]
    tolerance_percent = alert.get("tolerancePercent", 1.0)
    threshold = target_price * (1 + tolerance_percent / 100)
    return price <= threshold
