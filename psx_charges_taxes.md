# PSX Trade Charges & Taxes (Stock Book Reference)

> **Source:** Derived from a real Floret Capitals trade confirmation (TISL, 08-Oct-2026 buy and 09-Oct-2026 sell).
> **Important:** Percentage rates below are *approximate*, back-calculated from the statement. Make them configurable in the app and verify against the broker's official rate sheet before relying on them.

---

## 1. Charge Types

| Charge | Full Form | Basis | Approx. Rate | Applies On |
|---|---|---|---|---|
| **Commission** | Broker Commission | % of trade value (broker-specific) | 0 on this account | Buy and Sell |
| **CDC** | Central Depository Company | **Per share** | Rs 0.0025 / share | Buy and Sell |
| **PSX Laga** | Pakistan Stock Exchange Levy | % of trade value | ~0.00425% | Buy and Sell |
| **SECP Laga** | Securities and Exchange Commission of Pakistan Levy | % of trade value | ~0.0006% | Buy and Sell |
| **NCCPL** | National Clearing Company of Pakistan Limited | % of trade value | ~0.0042% | Buy and Sell |
| **SST** | Sindh Sales Tax | % of **commission** | 0 here (commission is 0) | Buy and Sell |
| **CVT** | Capital Value Tax | % of value | 0.00 on statement | n/a here |
| **Other Charges** | Misc. fees | Varies | 0.00 | n/a here |
| **OTC** | Other Transaction Charges (statement column) | Sum of PSX + SECP + NCCPL | not a separate charge | Display total |
| **CGT** | Capital Gains Tax | % of **profit** (not trade value) | Depends on holding period and filer status | Sell (profit only) |

---

## 2. Formulas

```
tradeValue      = quantity × rate

cdc             = quantity × 0.0025
psxLaga         = tradeValue × 0.0000425
secpLaga        = tradeValue × 0.000006
nccpl           = tradeValue × 0.0000418
otc             = psxLaga + secpLaga + nccpl

commission      = tradeValue × brokerCommissionRate      // 0 for this account
sst             = commission × sstRate                   // 0 when commission = 0

totalCharges    = commission + cdc + psxLaga + secpLaga + nccpl + sst + otherCharges

BUY  netAmount  = tradeValue + totalCharges
SELL netAmount  = tradeValue - totalCharges

avgCostNet (buy)   = BUY netAmount / quantity
avgSellNet (sell)  = SELL netAmount / quantity

profit (net)    = SELL netAmount - BUY netAmount
```

**Key points**

- Charges apply on **both buy and sell**, so a round trip pays charges twice.
- **CDC depends on quantity only.** More shares means more CDC, regardless of price.
- **PSX + SECP + NCCPL depend on trade value** (quantity × rate).
- Charges are **not fixed**. They change with quantity and rate.
- On a lot-based app, calculate charges **per lot/trade**, then sum.

---

## 3. Worked Example (from the real statement)

### BUY: 2,000 TISL @ Rs 4.91

| Item | Amount (Rs) |
|---|---|
| Trade value | 9,820.00 |
| CDC | 5.00 |
| PSX Laga | 0.42 |
| SECP Laga | 0.06 |
| NCCPL | 0.41 |
| Commission / SST / Other | 0.00 |
| **Total charges** | **5.89** |
| **Net buy amount** | **9,825.89** |
| Avg cost (net) | 4.9129 / share |

### SELL: 2,000 TISL (94 @ 4.94 and 1,906 @ 4.99)

| Item | Amount (Rs) |
|---|---|
| Trade value | 9,975.30 |
| CDC | 5.00 |
| PSX Laga | 0.42 |
| SECP Laga | 0.06 |
| NCCPL | 0.42 |
| **Total charges** | **5.90** |
| **Net sell amount** | **9,969.40** |
| Avg sell (net) | 4.9847 / share |

### Result

| Item | Amount (Rs) |
|---|---|
| Gross profit (9,975.30 − 9,820.00) | 155.30 |
| Total charges (5.89 + 5.90) | 11.79 |
| **Net profit** | **143.51** |

Ledger check: 10,000 (funds received) + 143.51 = **10,143.51** closing balance.

---

## 4. Test Cases for the Calculator

Use these to verify the app's output (allow ±Rs 0.01 rounding difference):

| Case | Qty | Rate | Side | Expected Total Charges |
|---|---|---|---|---|
| 1 | 2,000 | 4.91 | Buy | 5.89 |
| 2 | 94 | 4.94 | Sell | ~0.30 (CDC 0.24 + PSX 0.02 + NCCPL 0.02 + SECP 0.00, rounded) |
| 3 | 1,906 | 4.99 | Sell | ~5.63 (CDC 4.77 + PSX 0.40 + SECP 0.06 + NCCPL 0.40) |
| 4 | 2,000 | 4.9877 (avg) | Sell | 5.90 |

---

## 5. Approximate Charges by Trade Size (Buy Side)

| Trade | Value (Rs) | CDC | PSX+SECP+NCCPL | Total |
|---|---|---|---|---|
| 1,000 @ Rs 5 | 5,000 | 2.50 | 0.45 | 2.95 |
| 2,000 @ Rs 4.91 | 9,820 | 5.00 | 0.89 | 5.89 |
| 10,000 @ Rs 5 | 50,000 | 25.00 | 4.53 | 29.53 |
| 2,000 @ Rs 50 | 100,000 | 5.00 | 9.06 | 14.06 |

---

## 6. Break-Even

```
breakEvenPerShare ≈ (buyCharges + sellCharges) / quantity
```

For the sample trade: 11.79 / 2,000 ≈ **Rs 0.006 per share**.
For low-priced stocks (around Rs 5), CDC is a bigger percentage (0.0025 / 5 = 0.05% per side), so charges matter more.

---

## 7. Capital Gains Tax (CGT)

- **Not shown** on the trade confirmation or ledger.
- Applies to **profit**, not trade value.
- Rate depends on **holding period** and **filer / non-filer status**.
- Collected by NCCPL / FBR separately, so confirm the current rate with the broker (Floret Capitals).
- Suggested app design: keep CGT as an **optional, configurable setting** (rate % plus on/off toggle), applied only when net profit > 0.

---

## 8. Reference: Statement Short Forms

| Short Form | Full Form |
|---|---|
| PSX | Pakistan Stock Exchange |
| CDC | Central Depository Company |
| NCCPL | National Clearing Company of Pakistan Limited |
| SECP | Securities and Exchange Commission of Pakistan |
| FBR | Federal Board of Revenue |
| SST | Sindh Sales Tax |
| CVT | Capital Value Tax |
| CGT | Capital Gains Tax |
| REG | Regular Market |
| BO | Client/beneficial owner trade flag (broker-specific) |
| AVG(G) / AVG(N) | Average Gross / Average Net |
| AVG(FIFO) | Average, First-In-First-Out |
| H/C | Haircut |
| Dr. / Cr. | Debit / Credit |
| RC / PS | Receipt voucher / Purchase-Sale voucher |

---

## 9. Dart Implementation Sketch (Flutter)

```dart
class ChargeRates {
  final double cdcPerShare;
  final double psxLaga;
  final double secpLaga;
  final double nccpl;
  final double commissionRate; // fraction of trade value
  final double sstRate;        // fraction of commission
  final double otherCharges;

  const ChargeRates({
    this.cdcPerShare = 0.0025,
    this.psxLaga = 0.0000425,
    this.secpLaga = 0.000006,
    this.nccpl = 0.0000418,
    this.commissionRate = 0.0,
    this.sstRate = 0.0,
    this.otherCharges = 0.0,
  });
}

class TradeCharges {
  final double tradeValue;
  final double cdc, psx, secp, nccpl, commission, sst, other;

  TradeCharges({
    required this.tradeValue,
    required this.cdc,
    required this.psx,
    required this.secp,
    required this.nccpl,
    required this.commission,
    required this.sst,
    required this.other,
  });

  double get otc => psx + secp + nccpl;
  double get total => commission + cdc + psx + secp + nccpl + sst + other;
}

double _r2(double v) => (v * 100).roundToDouble() / 100;

TradeCharges calculateCharges({
  required int quantity,
  required double rate,
  ChargeRates r = const ChargeRates(),
}) {
  final value = quantity * rate;
  final commission = _r2(value * r.commissionRate);
  return TradeCharges(
    tradeValue: _r2(value),
    cdc: _r2(quantity * r.cdcPerShare),
    psx: _r2(value * r.psxLaga),
    secp: _r2(value * r.secpLaga),
    nccpl: _r2(value * r.nccpl),
    commission: commission,
    sst: _r2(commission * r.sstRate),
    other: r.otherCharges,
  );
}

double netBuyAmount(TradeCharges c) => c.tradeValue + c.total;
double netSellAmount(TradeCharges c) => c.tradeValue - c.total;
```

**Implementation notes**

- Store `ChargeRates` in settings (Hive) so rates can be edited without an app update.
- Let the user override the calculated charges with the actual amounts from the broker statement.
- Round each charge to 2 decimals separately, then sum, which matches how the statement is built.
- For lots, compute charges per execution, then allocate to lots for P/L.

---

*Rates are derived from one statement and are approximate. Confirm exact rates with the broker before using for accounting.*
