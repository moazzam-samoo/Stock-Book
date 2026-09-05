"""Pure decision logic for sell- and buy-target alerts.

No Firebase or network imports here, deliberately — every function takes
plain dicts and returns a plain decision, so this module is unit-testable
without credentials and without touching the network.
"""

# Alerts are deliberately NOT one-shot: once a target is first crossed, the
# alert keeps re-firing on every further move in the user's favor (a sell
# alert on continued gains, a buy alert on a continued dip) — rather than
# going silent after the first notification. To keep that from firing on
# every single 5-minute check while price is merely hovering, a repeat only
# fires once price has moved at least this much further since the *last*
# notification, not merely still past the original target.
REPEAT_ALERT_STEP_PERCENT = 1.0


def should_fire_sell(position: dict, price: float) -> bool:
    """A sell alert fires once a position's live price reaches its target,
    then again on every further REPEAT_ALERT_STEP_PERCENT climb.

    `lastAlertPrice` (unset on a position that has never fired) is the
    baseline for repeat firing; the original `targetPrice` is only the
    baseline for the very first fire.
    """
    target_price = position.get("targetPrice")
    if target_price is None:
        return False

    last_alert_price = position.get("lastAlertPrice")
    if last_alert_price is None:
        return price >= target_price
    return price >= last_alert_price * (1 + REPEAT_ALERT_STEP_PERCENT / 100)


def should_fire_buy(alert: dict, price: float) -> bool:
    """A buy alert fires once price drops to or within tolerance of target,
    then again on every further REPEAT_ALERT_STEP_PERCENT drop.

    Threshold: price <= targetPrice * (1 + tolerancePercent / 100). Must
    match Phase 07's `alertThreshold()`/`isAlertTriggered()` (Dart) exactly,
    including boundary behaviour: exactly at the threshold fires.

    `isActive` is no longer flipped false on firing (that was the one-shot
    design) — it now only means "not manually paused/deleted", so a repeat
    fire is gated purely on `lastAlertPrice`, the same as the sell side.
    """
    if not alert.get("isActive", False):
        return False

    target_price = alert["targetPrice"]
    tolerance_percent = alert.get("tolerancePercent", 1.0)
    threshold = target_price * (1 + tolerance_percent / 100)

    last_alert_price = alert.get("lastAlertPrice")
    if last_alert_price is None:
        return price <= threshold
    return price <= last_alert_price * (1 - REPEAT_ALERT_STEP_PERCENT / 100)
