"""Scrapes PSX's own homepage for its live Market Status indicator.

Deliberately a second, independent scrape from price_source.py's psxdata
screener call — different site section, different failure modes. A layout
change on the homepage must not be able to take down the price fetch, and
vice versa; each has its own try/except at the call site in main.py.
"""

import re

import requests
from bs4 import BeautifulSoup

PSX_HOMEPAGE_URL = "https://www.psx.com.pk"

# Confirmed live 2026-09-05: the homepage's "Market Highlights" section
# renders "Market Status" as a label with "Open" or "Closed" as its value,
# under the "Market Status" heading. The exact DOM nesting (which element is
# the label vs. the value) isn't something we pin to — a flat text search is
# resilient to markup changes that a precise CSS-selector path is not.
_MARKET_STATUS_PATTERN = re.compile(r"Market Status\W{0,10}(Open|Closed)", re.IGNORECASE)


def fetch_market_status() -> dict | None:
    """Returns {"isOpen": bool, "label": str}, or None if the homepage
    couldn't be fetched or the Market Status text couldn't be found.

    On None, the caller must skip writing market_status/current entirely —
    never write a guessed or stale value. The client already treats a
    missing/stale doc as "unknown, show nothing" (Phase 04B), which is the
    correct degraded state; a wrong `isOpen` would be worse than nothing.
    """
    try:
        response = requests.get(PSX_HOMEPAGE_URL, timeout=15)
        response.raise_for_status()
    except requests.RequestException:
        return None

    label = _parse_market_status_label(response.text)
    if label is None:
        return None

    return {"isOpen": label.strip().lower() == "open", "label": label.strip()}


def _parse_market_status_label(html: str) -> str | None:
    soup = BeautifulSoup(html, "html.parser")
    visible_text = soup.get_text(separator=" ", strip=True)
    match = _MARKET_STATUS_PATTERN.search(visible_text)
    if match is None:
        return None
    return match.group(1)
