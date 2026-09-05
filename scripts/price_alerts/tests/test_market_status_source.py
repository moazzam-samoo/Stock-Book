from unittest.mock import Mock, patch

import requests

import market_status_source as mss


def _mock_response(html: str, raise_for_status_error: Exception | None = None) -> Mock:
    response = Mock()
    response.text = html
    if raise_for_status_error is not None:
        response.raise_for_status.side_effect = raise_for_status_error
    else:
        response.raise_for_status.return_value = None
    return response


def test_12_parses_open():
    html = "<div>Market Highlights</div><div>Market Status</div><div>Open</div>"
    with patch("market_status_source.requests.get", return_value=_mock_response(html)):
        result = mss.fetch_market_status()

    assert result == {"isOpen": True, "label": "Open"}


def test_13_parses_closed():
    html = "<div>Market Highlights</div><div>Market Status</div><div>Closed</div>"
    with patch("market_status_source.requests.get", return_value=_mock_response(html)):
        result = mss.fetch_market_status()

    assert result == {"isOpen": False, "label": "Closed"}


def test_14_homepage_fetch_failure_returns_none():
    """A network failure must not be guessed at — the caller (main.py)
    skips writing market_status/current entirely on None."""
    with patch(
        "market_status_source.requests.get",
        side_effect=requests.ConnectionError("boom"),
    ):
        result = mss.fetch_market_status()

    assert result is None


def test_parse_failure_when_market_status_text_is_absent():
    html = "<div>Some unrelated PSX homepage content</div>"
    with patch("market_status_source.requests.get", return_value=_mock_response(html)):
        result = mss.fetch_market_status()

    assert result is None


def test_5xx_response_returns_none():
    with patch(
        "market_status_source.requests.get",
        return_value=_mock_response("", raise_for_status_error=requests.HTTPError("500")),
    ):
        result = mss.fetch_market_status()

    assert result is None
