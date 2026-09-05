import alerts


def test_1_sell_fires_at_price_at_or_above_target():
    """First fire ever (no lastAlertPrice yet) is gated on the original target."""
    position = {"targetPrice": 100.0, "lastAlertPrice": None}
    assert alerts.should_fire_sell(position, 100.0) is True
    assert alerts.should_fire_sell(position, 105.0) is True


def test_2_sell_does_not_fire_below_target():
    position = {"targetPrice": 100.0, "lastAlertPrice": None}
    assert alerts.should_fire_sell(position, 99.99) is False


def test_3_sell_does_not_repeat_until_it_climbs_a_further_step():
    """Not one-shot, but not spammy either: having already fired at 100.0,
    a price that's still above the original target but hasn't climbed the
    further REPEAT_ALERT_STEP_PERCENT must not re-fire."""
    position = {"targetPrice": 100.0, "lastAlertPrice": 100.0}
    assert alerts.should_fire_sell(position, 100.5) is False
    assert alerts.should_fire_sell(position, 100.99) is False


def test_3b_sell_fires_again_on_a_further_climb():
    position = {"targetPrice": 100.0, "lastAlertPrice": 100.0}
    assert alerts.should_fire_sell(position, 101.0) is True  # exactly +1%
    assert alerts.should_fire_sell(position, 110.0) is True


def test_3c_sell_does_not_fire_again_on_a_dip_back_toward_the_last_alert():
    """A price that falls back below the last alert price (but still above
    the original target) must not re-fire — repeat fires are gated on new
    highs since the last alert, not "still above target"."""
    position = {"targetPrice": 100.0, "lastAlertPrice": 105.0}
    assert alerts.should_fire_sell(position, 102.0) is False


def test_4_sell_skipped_when_target_price_is_null():
    position = {"targetPrice": None, "lastAlertPrice": None}
    assert alerts.should_fire_sell(position, 150.0) is False


def test_5_buy_fires_at_exactly_the_threshold():
    # target 8.60, tolerance 1.0% -> threshold 8.686
    alert = {
        "targetPrice": 8.60,
        "tolerancePercent": 1.0,
        "isActive": True,
        "lastAlertPrice": None,
    }
    assert alerts.should_fire_buy(alert, 8.686) is True


def test_6_buy_does_not_fire_a_hair_above():
    alert = {
        "targetPrice": 8.60,
        "tolerancePercent": 1.0,
        "isActive": True,
        "lastAlertPrice": None,
    }
    assert alerts.should_fire_buy(alert, 8.687) is False


def test_7_buy_skipped_when_inactive():
    """isActive no longer means "hasn't fired yet" — it's a live pause/delete
    flag, checked independently of the repeat-fire logic."""
    inactive = {
        "targetPrice": 8.60,
        "tolerancePercent": 1.0,
        "isActive": False,
        "lastAlertPrice": None,
    }
    assert alerts.should_fire_buy(inactive, 8.60) is False


def test_7b_buy_does_not_repeat_until_it_drops_a_further_step():
    alert = {"targetPrice": 8.60, "tolerancePercent": 1.0, "isActive": True, "lastAlertPrice": 8.60}
    assert alerts.should_fire_buy(alert, 8.55) is False  # not yet a further 1% down


def test_7c_buy_fires_again_on_a_further_drop():
    alert = {"targetPrice": 8.60, "tolerancePercent": 1.0, "isActive": True, "lastAlertPrice": 8.60}
    assert alerts.should_fire_buy(alert, 8.60 * 0.99) is True  # exactly -1%
    assert alerts.should_fire_buy(alert, 8.00) is True


def test_7d_buy_stays_active_after_firing_so_it_can_repeat():
    """Confirms the lifecycle change directly: an alert that has already
    fired (has a lastAlertPrice) and remains isActive keeps evaluating for
    further drops — it is not implicitly done."""
    alert = {"targetPrice": 8.60, "tolerancePercent": 1.0, "isActive": True, "lastAlertPrice": 8.50}
    assert alerts.should_fire_buy(alert, 8.415) is True  # 8.50 * 0.99
