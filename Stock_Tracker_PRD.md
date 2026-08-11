# Product Requirements Document (PRD)
## Stock Investment Tracker — Flutter + Firebase App

| Field | Detail |
|---|---|
| **Document Owner** | Product Owner (You) |
| **Status** | Draft v1.0 |
| **Last Updated** | August 3, 2026 |
| **Platforms** | Mobile (iOS + Android) & Desktop (Windows + macOS + Linux) |
| **Tech Stack** | Flutter (single codebase) + Firebase (Firestore, Auth) |

---

## 1. Problem Statement

The current solution is a manually-maintained Excel workbook. It works for a single buy/sell pair per stock lot, but breaks down when a position is sold in multiple partial tranches — each new partial sale requires manually inserting new spreadsheet columns and rewriting formulas. This is:
- **Error-prone** (formula/reference mistakes on every edit)
- **Not scalable** (columns keep growing sideways forever)
- **Not accessible on the go** (no real mobile experience)
- **Single-device** (no sync between phone and computer)

**Goal:** Replace the spreadsheet with a purpose-built app that models each *sale* as its own record (not a column), syncs in real time between a mobile app and a desktop app, and gives an always-accurate portfolio dashboard.

---

## 2. Goals & Success Metrics

### Business/Personal Goals
- Track every stock buy and every (partial or full) sell accurately, with zero manual formula maintenance.
- View real-time portfolio health (invested amount, realized P/L, open positions) from any device.
- Eliminate the "column explosion" problem permanently via a proper relational data model.

### Success Metrics (MVP)
| Metric | Target |
|---|---|
| Time to log a new sale | < 15 seconds |
| Data sync latency (mobile ⇄ desktop) | < 2 seconds |
| Dashboard calculation accuracy | 100% (no manual formula errors) |
| Crash-free session rate | > 99% |

---

## 3. Target User / Persona

**Primary user:** A single retail investor (you) who:
- Buys stocks in lots at different times.
- Sells the same lot in multiple partial tranches, on different dates/prices.
- Wants to check portfolio status from phone (mobile) or PC (desktop).
- Is not a professional trader — needs simple, fast data entry, not complex charting terminals.

> MVP is designed for **single-user, personal use**. Multi-user/family sharing is a possible future phase (see §10).

---

## 4. Scope

### ✅ In Scope (MVP)
- Add a **Buy transaction** (lot): stock ticker, buy date, shares purchased, buy price/share.
- Add **one or more Sell events** against any open lot, each with its own date, price/share, and quantity — no limit on number of partial sells.
- Auto-calculated per-lot fields: amount invested, amount received, realized profit/loss, profit/share, shares remaining, status (Open / Partially Sold / Closed).
- **Dashboard**: total invested, total realized P/L, free cash, per-stock summary (shares held, amount invested open, avg buy price, position status).
- Edit / delete a transaction or a sell event.
- Transaction history view (searchable/filterable by stock, date, status).
- Real-time sync between mobile and desktop via Firebase.
- Basic authentication (so data is tied to one Firebase account, accessible from both apps).
- Offline support: app usable without internet; syncs when back online.

### ❌ Out of Scope (MVP) — candidates for later phases
- Live stock price feeds / market data integration.
- Multi-currency support.
- Multi-user sharing / family portfolios.
- Tax reporting / export to accounting software.
- Charting/technical analysis tools.
- Broker API integration (auto-import trades).

---

## 5. Core Data Model (the fix for the Excel problem)

Instead of adding columns for each sale, each **sale is its own document** linked to a **lot**. This is the central architectural improvement over the spreadsheet.

```
users/{userId}
  └── lots/{lotId}
        - stockTicker: string          e.g. "STPL"
        - buyDate: timestamp
        - sharesPurchased: number
        - buyPricePerShare: number
        - amountInvested: number        (derived: sharesPurchased × buyPricePerShare)
        - createdAt: timestamp
        └── sales/{saleId}              (sub-collection — unlimited sale events)
              - sellDate: timestamp
              - sellPricePerShare: number
              - sharesSold: number
              - amountReceived: number   (derived: sharesSold × sellPricePerShare)
              - createdAt: timestamp
```

### Derived / computed values (calculated client-side or via Cloud Function, never manually entered)
Per lot:
- `totalSharesSold` = SUM(sales.sharesSold)
- `sharesRemaining` = sharesPurchased − totalSharesSold
- `amountInvestedRemaining` = (sharesRemaining ÷ sharesPurchased) × amountInvested
- `totalAmountReceived` = SUM(sales.amountReceived)
- `realizedProfitLoss` = totalAmountReceived − ((totalSharesSold ÷ sharesPurchased) × amountInvested)
- `status`:
  - `totalSharesSold == 0` → **Open**
  - `0 < totalSharesSold < sharesPurchased` → **Partially Sold**
  - `totalSharesSold == sharesPurchased` → **Closed**

Per stock (aggregated across all lots with that ticker):
- Shares Held (Open) = SUM(sharesRemaining across lots)
- Amount Invested (Open) = SUM(amountInvestedRemaining across lots)
- Realized P/L = SUM(realizedProfitLoss across lots)
- Avg Buy Price (Open) = Amount Invested (Open) ÷ Shares Held (Open)
- Position Status = Fully Sold / Partially Sold — X Remaining / Not Sold Yet

Portfolio-level (dashboard):
- Total Invested Money = starting capital (user-set)
- Currently Invested = SUM(amountInvestedRemaining, all lots)
- Total Realized P/L = SUM(realizedProfitLoss, all lots)
- Free Cash = Starting Capital + Total Realized P/L − Currently Invested

> This model supports **infinite partial sales per lot** with zero schema changes — solving the exact problem that broke the spreadsheet.

---

## 6. Functional Requirements

### 6.1 Authentication
- FR-1: User can sign up / log in via Firebase Auth (email+password, or Google Sign-In) on both mobile and desktop.
- FR-2: Session persists across app restarts.

### 6.2 Buy (Lot) Entry
- FR-3: User can add a new lot: ticker, buy date, shares purchased, buy price/share.
- FR-4: Amount invested is auto-calculated and displayed, not editable.

### 6.3 Sell Entry
- FR-5: From any open or partially-sold lot, user can add a new sell event: sell date, sell price/share, shares sold.
- FR-6: App validates shares sold (this event) ≤ shares remaining (prevents over-selling).
- FR-7: Multiple sell events can be added to the same lot over time, with no upper limit.
- FR-8: Each sell event is individually editable/deletable; totals recalculate automatically.

### 6.4 Dashboard
- FR-9: Dashboard shows: Total Invested, Currently Invested, Total Realized P/L, Free Cash (all real-time).
- FR-10: Per-stock summary table: ticker, shares held, amount invested (open), realized P/L, avg buy price, position status.
- FR-11: Tapping a stock row drills into that stock's lot/sale history.

### 6.5 Transaction History
- FR-12: List/filter all lots by stock, date range, or status (Open/Partial/Closed).
- FR-13: Each lot expands to show its individual sale events (date, price, qty, received, P/L for that event).

### 6.6 Sync & Offline
- FR-14: All reads/writes go through Firestore, so mobile and desktop reflect changes within seconds of each other.
- FR-15: App remains usable offline (Firestore offline persistence); changes sync when connectivity returns.

---

## 7. Non-Functional Requirements

| Category | Requirement |
|---|---|
| **Performance** | Dashboard recalculation < 500ms for up to ~2,000 lots/sales |
| **Security** | Firestore Security Rules restrict all reads/writes to `request.auth.uid == userId`; no data is publicly readable |
| **Availability** | Offline-first; no data loss on connectivity drop |
| **Platforms** | Flutter build targets: Android, iOS, Windows, macOS, Linux (single codebase) |
| **Accessibility** | Support system font scaling, screen-reader labels on key financial figures |
| **Data integrity** | All monetary calculations done via a single shared Dart calculation module (used identically on mobile & desktop) to avoid drift |

---

## 8. Technical Architecture

```
┌─────────────────┐     ┌─────────────────┐
│  Flutter Mobile  │     │ Flutter Desktop  │
│  (iOS/Android)   │     │ (Win/Mac/Linux)  │
└────────┬─────────┘     └────────┬─────────┘
         │                        │
         │   Same Dart codebase   │
         │   (shared business    │
         │    logic + UI widgets) │
         │                        │
         └──────────┬─────────────┘
                     │
             ┌───────▼────────┐
             │ Firebase Auth   │  ← Login/session
             └───────┬────────┘
                     │
             ┌───────▼────────┐
             │ Cloud Firestore │  ← Real-time DB (lots + sales)
             │ + Security Rules│
             └───────┬────────┘
                     │
          (optional) ▼
             ┌────────────────┐
             │ Cloud Functions │  ← Server-side aggregate recalculation
             │  (if needed for │     if client-side calc proves insufficient
             │   heavy reports)│
             └────────────────┘
```

**Key architectural decisions:**
- **Single Flutter codebase** for mobile + desktop — shared widgets where layouts allow, responsive/adaptive layout for desktop's larger screen (e.g., side-nav + master-detail view) vs. mobile's bottom-nav + stacked views.
- **State management:** Riverpod (recommended) or Provider for reactive state tied to Firestore streams.
- **Firestore over Realtime Database** — better querying (filter by ticker/status/date) and offline support.
- **Client-side calculation module** shared between platforms so the math is defined exactly once (this is what the spreadsheet formulas were trying, and failing, to do by hand).

---

## 9. Key Screens (MVP)

1. **Login / Sign-up**
2. **Dashboard** — portfolio totals + per-stock summary table + Position Status
3. **Add Lot (Buy)** — simple form
4. **Lot Detail** — shows lot info + list of sale events + "Add Sale" button
5. **Add Sale** — form with over-sell validation
6. **Transaction History** — filterable list of all lots
7. **Settings** — starting capital, currency, logout

---

## 10. Future Phases (Post-MVP)

| Phase | Feature |
|---|---|
| V2 | Live price feed integration (auto-fetch current market price for unrealized gain/loss) |
| V2 | Charts: portfolio value over time, per-stock performance |
| V3 | Multi-user / shared portfolios (e.g., family) |
| V3 | Export to PDF/Excel for tax filing |
| V4 | Broker API integration for auto-importing trades |

---

## 11. Risks & Assumptions

| Risk | Mitigation |
|---|---|
| Firestore costs scale with reads/writes | Low personal-use volume — well within free tier for MVP |
| Desktop Flutter support is less mature than mobile | Test early on target OS; fall back to mobile-only MVP if desktop blockers arise |
| Data migration from existing Excel file | Build a one-time CSV/Excel importer to seed Firestore from the existing workbook |
| Floating-point rounding in financial math | Use fixed 2-decimal rounding consistently in the shared calculation module |

**Assumption:** Single-user personal use for MVP — no need for complex roles/permissions yet.

---

## 12. Open Questions

1. Currency: PKR only, or multi-currency later?
2. Should "Starting Capital" be a one-time fixed value, or should the app support adding capital over time (deposits)?
3. Do you want the existing Excel data migrated into the app on day one, or start fresh?

---

## 13. Recommended MVP Timeline (rough estimate, solo dev)

| Milestone | Duration |
|---|---|
| Firebase setup + Auth | 2–3 days |
| Data model + Firestore rules | 2 days |
| Add Lot / Add Sale flows | 4–5 days |
| Dashboard + calculations | 4–5 days |
| Transaction history + filters | 3 days |
| Desktop-specific layout adjustments | 3 days |
| Testing + polish | 4–5 days |
| **Total** | **~4 weeks** |
