"""Generates unique, one-time-use Pin Stocks premium unlock codes.

Run-it-yourself, not scheduled anywhere — unlike scripts/price_alerts/, this
has no cron/workflow. Reuses the same Admin SDK bootstrap
(price_alerts/firestore_io.py's init_firestore) and the same
FIREBASE_SERVICE_ACCOUNT_PATH env var convention as that backend.

Usage:
    FIREBASE_SERVICE_ACCOUNT_PATH=service-account.json \
        python scripts/generate_premium_codes.py --count 10

Prints the generated codes to stdout — copy them from there and hand them
out manually (there is no separate "list all codes" tool, deliberately: the
Firestore rules only ever allow looking up one exact code by ID, never
listing the collection, so this script's own printed output is the only
record of which codes exist unredeemed).
"""

import argparse
import os
import secrets
import sys

sys.path.insert(0, os.path.join(os.path.dirname(__file__), "price_alerts"))

import firestore_io  # noqa: E402 — path insert must happen first
from firebase_admin import firestore  # noqa: E402


def generate_code() -> str:
    """`STCK-XXXX-XXXX` — readable enough to type/dictate, ~10^9 possible
    codes per prefix segment, plenty for a human-distributed unlock code."""
    part = lambda: secrets.token_hex(2).upper()  # noqa: E731
    return f"STCK-{part()}-{part()}"


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--count", type=int, default=1, help="how many codes to generate")
    args = parser.parse_args()

    service_account_path = os.environ["FIREBASE_SERVICE_ACCOUNT_PATH"]
    db = firestore_io.init_firestore(service_account_path)

    codes = []
    while len(codes) < args.count:
        code = generate_code()
        ref = db.collection("premium_codes").document(code)
        if ref.get().exists:
            continue  # astronomically unlikely, but never overwrite a real code
        ref.set(
            {
                "redeemed": False,
                "redeemedBy": None,
                "redeemedAt": None,
                "createdAt": firestore.SERVER_TIMESTAMP,
            }
        )
        codes.append(code)

    print(f"Generated {len(codes)} code(s):")
    for code in codes:
        print(f"  {code}")


if __name__ == "__main__":
    main()
