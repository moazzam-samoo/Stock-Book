# Phase 08 — Backend: psxdata on GitHub Actions

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** Phases 04, 06, 07 (their Firestore schemas) · **Estimated:** 2 days · **Branch:** `feat/positions-and-alerts`

The only non-Dart phase. A Python script on a schedule fetches PSX prices, writes them to
`market_prices/`, and sends the pushes that Phases 06 and 07 set up.

---

## Context you need

- **Not Cloud Functions.** The Firebase project is on the **Spark (free) plan**, which has no Cloud
  Scheduler and no outbound network from Functions. GitHub Actions provides the schedule for free.
  Firestore and FCM themselves are free on Spark.
- **The repo is public**, so Actions minutes are unlimited. No cost concern.
- **There is no PSX API key.** PSX publishes no public developer API. `psxdata` scrapes the public
  site. This is why the fetch must sit behind a swappable interface (Task 2).

---

## Task 1 — Structure

```
scripts/price_alerts/
├── main.py            # orchestration only
├── price_source.py    # the swappable fetch seam
├── alerts.py          # PURE decision logic, no I/O
├── firestore_io.py    # all Firestore reads/writes
└── requirements.txt
```

**`alerts.py` must have no Firebase or network imports at all.** It takes plain dicts and returns
decisions. That is what makes it unit-testable without credentials, and the tests below depend on it.

---

## Task 2 — `price_source.py`

```python
class PriceSource(Protocol):
    def fetch_prices(self, tickers: set[str]) -> dict[str, float]: ...

class PsxdataScreenerSource:
    def fetch_prices(self, tickers): ...
```

**Use `psxdata.screener()`, not a per-ticker loop.** It returns the whole board (~729 symbols) in
**one** request; filter locally. The original draft plan looped `psxdata.quote(ticker)` per ticker —
that would be ~30 sequential scrapes per run, 28 runs a day: slower, far more fragile, and much
heavier on PSX's servers for no benefit.

- **Pin the version.** `psxdata==1.1.0` (released 2026-09-02). Do not float it — the package's
  `0.1.0a*` alpha line is recent history and it is young.
- Requires **Python 3.11+**.
- A ticker missing from the screener → **omit it from the returned dict**. Never substitute `0`,
  never guess. A `0` price would fire every buy alert at once.
- Wrap the fetch in a try/except: a scrape failure must abort the run cleanly, not send garbage.

---

## Task 3 — `alerts.py` (pure)

```python
def should_fire_sell(position: dict, price: float) -> bool
    # targetPrice set, targetAlertSent False, price >= targetPrice

def should_fire_buy(alert: dict, price: float) -> bool
    # isActive, not alertSent, price <= targetPrice * (1 + tolerancePercent/100)
```

**The buy threshold must match Phase 07's Dart implementation exactly.** Phase 07's tests are the
reference definition of that formula; port it, don't reinvent it, and use the same boundary
behaviour (at exactly the threshold → fires).

---

## Task 4 — `main.py`

1. Auth via service account (`FIREBASE_SERVICE_ACCOUNT_PATH` env var,
   `firebase_admin.credentials.Certificate`).
2. Collection-group query `positions` where `status == "open"` → distinct held tickers.
3. Collection-group query `price_alerts` where `isActive == True` and `alertSent == False` →
   distinct watched tickers.
4. `fetch_prices(held | watched)` — **one call**.
5. Write each price to `market_prices/{ticker}` with `SERVER_TIMESTAMP`.
6. Sell alerts: for each qualifying position, send FCM to that user's `fcmToken`, then set
   `targetAlertSent: True` + `targetAlertSentAt`.
7. Buy alerts: for each qualifying alert, send FCM, then set `alertSent: True`, `isActive: False`,
   `alertSentAt`.

**Ordering rule: send the push first, then set the flag.** If the flag write fails after a successful
send, the worst case is one duplicate notification. If you flip the order and the send fails, the user
silently never gets the alert at all — the flag says "told you" when nobody was told.

**No `fcmToken` on the user → skip quietly.** Not an error; they simply haven't granted permission.

Uid extraction: `doc.reference.parent.parent.id` for `users/{uid}/positions/{id}`.

**Payload — must match Phase 05's contract exactly:**

```python
{"type": "sell", "ticker": ..., "positionId": ...}
{"type": "buy",  "ticker": ..., "alertId": ...}
```

FCM `data` values must all be **strings**. A float or None here fails at send time.

---

## Task 5 — Workflow

`.github/workflows/price-alerts.yml`:

```yaml
on:
  schedule:
    - cron: '*/15 4-10 * * 1-5'   # 09:15–15:30 PKT; Pakistan has no DST
  workflow_dispatch: {}
```

- `pip install -r scripts/price_alerts/requirements.txt` (pinned)
- Write `secrets.FIREBASE_SERVICE_ACCOUNT_JSON` to a file at runtime
- Add `service-account.json` to `.gitignore` as a safety net
- Run with `FIREBASE_SERVICE_ACCOUNT_PATH` pointing at it

### Operational caveats — put these in the workflow file as comments

- GitHub cron can run several minutes late under load. Fine at 15-minute granularity.
- **Scheduled workflows are auto-disabled after 60 days of repo inactivity.** If Stock Book goes
  quiet, alerts stop silently with no error anywhere. Mitigate with the staleness indicator from
  Phase 04, and mention a monthly heartbeat commit as an option.

### Indexes

Both collection-group queries need composite indexes. The first run throws `FailedPrecondition` with
a console link for each. Create them, then capture both into `firestore.indexes.json` so they are
versioned (`firebase deploy --only firestore:indexes` works on Spark).

---

## Required tests

`scripts/price_alerts/tests/` with `pytest` — no credentials, no network.

| # | Test | Asserts |
|---|---|---|
| 1 | Sell fires at `price >= target` | true |
| 2 | Sell does not fire below target | false |
| 3 | Sell skipped when `targetAlertSent` | false |
| 4 | Sell skipped when `targetPrice` is null | false |
| 5 | **Buy fires at exactly the threshold** | true — matches Phase 07 |
| 6 | Buy does not fire a hair above | false |
| 7 | Buy skipped when inactive or already sent | false |
| 8 | Missing `fcmToken` | skipped, no exception |
| 9 | **Ticker absent from screener** | skipped entirely — never treated as `0` |
| 10 | **Contract test vs. a recorded screener fixture** | a `psxdata` upgrade that renames columns fails in CI, not in production |

Test 10 is the one that protects against the scraping dependency breaking silently. Commit a real
captured `screener()` sample as a fixture.

---

## Acceptance criteria

- [ ] `pytest` green
- [ ] `workflow_dispatch` run succeeds against the real project
- [ ] `market_prices` populated; app (Phase 04) shows live prices
- [ ] A deliberately low sell target fires **once**, deep-links correctly, and does **not** re-fire
      on the next run
- [ ] A buy alert near a real price fires with correct tolerance behaviour
- [ ] Both composite indexes committed to `firestore.indexes.json`
- [ ] No secret committed anywhere — check the diff before pushing

## Manual setup (Moazzam's, not yours — list in report)

1. Firebase Console → Project Settings → Service Accounts → **Generate new private key**
2. GitHub → Settings → Secrets and variables → Actions → new secret
   **`FIREBASE_SERVICE_ACCOUNT_JSON`** = the full JSON contents

## Out of scope

Any Flutter code. Re-arming fired alerts. Historical price storage. Intraday data (PSX does not
expose historical intraday archives publicly).
