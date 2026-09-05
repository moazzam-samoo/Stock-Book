import alerts


def test_1_sell_fires_at_price_at_or_above_target():
    position = {"targetPrice": 100.0, "targetAlertSent": False}
    assert alerts.should_fire_sell(position, 100.0) is True
    assert alerts.should_fire_sell(position, 105.0) is True


def test_2_sell_does_not_fire_below_target():
    position = {"targetPrice": 100.0, "targetAlertSent": False}
    assert alerts.should_fire_sell(position, 99.99) is False


def test_3_sell_skipped_when_already_sent():
    position = {"targetPrice": 100.0, "targetAlertSent": True}
    assert alerts.should_fire_sell(position, 150.0) is False


def test_4_sell_skipped_when_target_price_is_null():
    position = {"targetPrice": None, "targetAlertSent": False}
    assert alerts.should_fire_sell(position, 150.0) is False


def test_5_buy_fires_at_exactly_the_threshold():
    # target 8.60, tolerance 1.0% -> threshold 8.686
    alert = {
        "targetPrice": 8.60,
        "tolerancePercent": 1.0,
        "isActive": True,
        "alertSent": False,
    }
    assert alerts.should_fire_buy(alert, 8.686) is True


def test_6_buy_does_not_fire_a_hair_above():
    alert = {
        "targetPrice": 8.60,
        "tolerancePercent": 1.0,
        "isActive": True,
        "alertSent": False,
    }
    assert alerts.should_fire_buy(alert, 8.687) is False


def test_7_buy_skipped_when_inactive_or_already_sent():
    base = {"targetPrice": 8.60, "tolerancePercent": 1.0}
    inactive = {**base, "isActive": False, "alertSent": False}
    already_sent = {**base, "isActive": True, "alertSent": True}

    assert alerts.should_fire_buy(inactive, 8.60) is False
    assert alerts.should_fire_buy(already_sent, 8.60) is False
