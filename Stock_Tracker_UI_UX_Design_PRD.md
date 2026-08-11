# UI/UX Design Specification
## Stock Investment Tracker — Mobile App + Desktop App

| Field | Detail |
|---|---|
| **Companion Doc** | Stock_Tracker_PRD.md (Product/Technical PRD) |
| **Platforms Covered** | Mobile (iOS/Android) & Desktop (Windows/macOS/Linux) |
| **Framework** | Flutter (shared design system, platform-adaptive layouts) |
| **Status** | Draft v1.0 |

---

## 1. Design Philosophy

**Personality:** Clean, trustworthy, calm fintech — data should feel confident and easy to scan, never cluttered. Numbers are the hero; decoration stays minimal.

**Principles:**
- **Clarity over cleverness** — profit/loss, remaining shares, and status must be readable at a glance.
- **Color carries meaning** — green = profit/gain, red = loss, amber = partial/in-progress, neutral gray = closed/settled. Same meaning on both platforms.
- **Motion with purpose** — animations explain *what changed* (a number going up, a chart filling in), never just decorative.
- **One design language, two layouts** — mobile and desktop share the same colors, type, icons, and components; only the *arrangement* (single column vs. multi-pane) changes.

---

## 2. Shared Design System

### 2.1 Color Palette

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#4F46E5` (Indigo) | Primary buttons, active nav, links |
| `primary-dark` | `#3730A3` | Pressed states, dark mode primary |
| `success` | `#16A34A` | Profit values, "Closed" success badge |
| `success-bg` | `#DCFCE7` | Success badge background |
| `danger` | `#DC2626` | Loss values |
| `danger-bg` | `#FEE2E2` | Loss badge background |
| `warning` | `#D97706` | "Partially Sold" badge |
| `warning-bg` | `#FEF3C7` | Partial badge background |
| `neutral-900` | `#111827` | Primary text |
| `neutral-500` | `#6B7280` | Secondary text |
| `neutral-100` | `#F3F4F6` | Card backgrounds (light mode) |
| `surface-dark` | `#1F2937` | Card backgrounds (dark mode) |
| `bg-dark` | `#0B0F19` | App background (dark mode, default) |

> **Default theme: Dark mode** (matches the finance-app convention and reduces eye strain for frequent checking) with a light-mode toggle in Settings.

### 2.2 Typography

| Style | Font | Size | Weight | Usage |
|---|---|---|---|---|
| Display | Inter / SF Pro | 32sp | 700 | Portfolio total value |
| H1 | Inter | 22sp | 700 | Screen titles |
| H2 | Inter | 17sp | 600 | Card titles, section headers |
| Body | Inter | 14sp | 400 | General text |
| Caption | Inter | 12sp | 400 | Timestamps, helper text |
| Numeric-Mono | JetBrains Mono / Roboto Mono | varies | 500 | All monetary/share figures — tabular alignment |

> Monetary and share-count figures use a **monospaced/tabular numeral font** so columns of numbers align cleanly — directly solving the "numbers looked messy" problem from the spreadsheet.

### 2.3 Core Components (shared library)

- **StatusBadge** — pill-shaped, color-coded: `Open` (neutral outline), `Partially Sold` (amber), `Closed` (green)
- **StatCard** — big number + label + small trend chip (↑ green / ↓ red)
- **StockRow** — ticker avatar (colored circle with 2-letter initials) + shares + avg price + status badge + mini sparkline
- **PrimaryButton / SecondaryButton / IconButton**
- **BottomSheet (mobile) / Modal Dialog (desktop)** — used for Add Buy / Add Sell forms
- **FavoriteChip** — small rounded chip with ticker + star icon, used in Settings and in the ticker autocomplete field
- **LineChart / DonutChart** — via `fl_chart` package
- **DataTable (desktop only)** — sortable, resizable columns, replicates the Excel table feel but fully automatic

---

## 3. MOBILE APP — Screen Specifications

### 3.1 Onboarding (2 Animated Pages)

**Page 1 — "Track Every Trade"**
```
┌─────────────────────────────┐
│                              │
│      [Animated Line Chart]  │   ← chart line draws itself
│     ╱╲    ╱╲                │      left→right over 1.6s,
│    ╱  ╲  ╱  ╲___╱            │      ease-out-cubic, with a
│   ╱    ╲╱                   │      glowing dot at the tip
│                              │      that pulses on arrival
│                              │
│    "Track Every Trade,      │   ← fades/slides up 0.3s
│     Down to the Last Share"  │      after chart settles
│                              │
│  Buy in tranches, sell in    │
│  tranches — we track every   │
│  partial sale automatically. │
│                              │
│      ●  ○                    │   ← page indicator dots
│                              │
│              [ Next → ]      │
└─────────────────────────────┘
```
- **Animation:** custom `CustomPainter` drawing an animated candlestick/line path (not a static Lottie of a generic chart — it should visually resemble real portfolio growth: dips and recoveries, ending on an upward note).
- **Timing:** 1.6s draw-in on page enter, loops a subtle "breathing" glow on the endpoint while the page is visible.
- **Package:** `fl_chart` animated controller, or `Rive` if a more illustrative style is wanted.

**Page 2 — "One Portfolio, Every Device"**
```
┌─────────────────────────────┐
│                              │
│   [Animated Donut Chart]    │   ← segments sweep in
│      ◔ ◑ ◕ ●                │      clockwise, one at a
│                              │      time, 200ms stagger
│                              │      each, spring easing
│                              │
│   "Your Portfolio, Synced   │
│    Everywhere Instantly"     │
│                              │
│  Log a sale on your phone —  │
│  see it on your desktop      │
│  the same second.            │
│                              │
│      ○  ●                    │
│                              │
│  [ Skip ]      [Get Started]│
└─────────────────────────────┘
```
- **Animation:** donut chart segments sweep in sequentially representing stock allocation (illustrative, not real data yet).
- **Transition between pages:** horizontal `PageView` with parallax — background chart shifts slower than foreground text for depth.
- **CTA:** "Get Started" → routes to Sign Up/Login.

---

### 3.2 Dashboard (Home Tab)

```
┌─────────────────────────────┐
│  Good evening 👋             │
│  Total Portfolio Value       │
│  Rs 24,018        ↑ 12.3%   │  ← Display-size number,
│                              │     green trend chip
│ ┌─────────┐ ┌─────────┐     │
│ │Invested │ │Realized │     │  ← 2x2 StatCard grid
│ │Rs 9,474 │ │ P/L     │     │
│ └─────────┘ │Rs 4,489 │     │
│ ┌─────────┐ └─────────┘     │
│ │Free Cash│ ┌─────────┐     │
│ │Rs 8,818 │ │Open Lots│     │
│ └─────────┘ │   2     │     │
│             └─────────┘     │
│                              │
│  Allocation                 │
│   [ Donut Chart ]           │  ← by stock, tap segment
│    STPL ●67%  BNL ●33%      │     highlights stock row below
│                              │
│  Your Stocks                │
│ ┌──────────────────────────┐│
│ │ 🟦 STPL   150 sh          ││  ← StockRow component
│ │ Avg Rs 8.45  [Partial]   ││     tap → Stock Detail
│ │ ╱╲___╱╲  (sparkline)      ││
│ ├──────────────────────────┤│
│ │ 🟩 BNL    630 sh          ││
│ │ Avg Rs 6.99  [Open]      ││
│ └──────────────────────────┘│
│                              │
│  [🏠][📄][⚙️]  ← bottom nav  │
└─────────────────────────────┘
```
- Pull-to-refresh triggers a Firestore re-fetch + a subtle number "count-up" animation on the StatCards (old value → new value over 400ms).
- Tapping a stock row navigates to **Stock Detail** (shows all lots + all sale events for that ticker — the direct replacement for the Excel row-by-row view).

---

### 3.3 Transactions Tab

```
┌─────────────────────────────┐
│  Transactions        🔍 ⏷   │  ← search + filter (by
│                              │     status/date/stock)
│ ┌──────────────────────────┐│
│ │ STPL · 1800 sh  Aug 3    ││  ← Lot card, tap to expand
│ │ [Partially Sold]         ││
│ │  ↳ Sold 600 @10.18 Aug 5 ││  ← expanded: each sale
│ │  ↳ Sold 600 @10.34 Aug 6 ││     event as its own line,
│ │  ↳ Sold 450 @11.23 Jul 8 ││     NOT a new column —
│ │  150 remaining           ││     this is the core fix
│ ├──────────────────────────┤│
│ │ BNL · 630 sh    Jul 13   ││
│ │ [Open]                   ││
│ └──────────────────────────┘│
│                              │
│                         ⊕   │  ← FAB, bottom-right
└─────────────────────────────┘
```

**Tapping the ⊕ FAB → Bottom Sheet:**
```
┌─────────────────────────────┐
│  ▼ (drag handle)             │
│                              │
│   [ 📈 Add Buy ]             │  ← two large tappable
│   [ 📉 Add Sell ]            │     options, icon + label
│                              │
└─────────────────────────────┘
```

**Add Buy form (bottom sheet expands full):**
```
┌─────────────────────────────┐
│  ✕            Add Buy        │
│                              │
│  Stock Ticker                │
│  [ STPL ▾ ]  ← autocomplete  │   from Favorites list
│                              │      (Settings), avoids
│  Buy Date        [📅 pick]   │      retyping tickers
│  Shares Purchased [______]   │
│  Buy Price/Share  [______]   │
│                              │
│  Amount Invested             │
│  Rs 15,210  (auto, greyed)   │  ← live-calculated as
│                              │     user types, non-editable
│         [ Save Buy ]         │
└─────────────────────────────┘
```

**Add Sell form (launched from a specific lot, or from FAB → picks lot first):**
```
┌─────────────────────────────┐
│  ✕            Add Sell       │
│                              │
│  Lot: STPL · Bought Aug 3    │
│  Remaining: 150 shares       │  ← context banner, read-only
│                              │
│  Sell Date        [📅 pick]  │
│  Sell Price/Share  [______]  │
│  Shares Sold       [______]  │  ← inline validation:
│                              │     error if > remaining
│  Amount Received             │
│  Rs 1,684  (auto)             │
│                              │
│         [ Save Sale ]        │
└─────────────────────────────┘
```
- **This directly replaces the "add new columns" workflow** — every new sale is just a new form submission, appended as a new sale record under the same lot. No schema change, no manual formula editing, ever again.

---

### 3.4 Settings Tab

```
┌─────────────────────────────┐
│  Settings                    │
│                              │
│  Favorite Stocks             │
│ ┌──────────────────────────┐│
│ │ ⭐ STPL   ⭐ BNL   [+ Add] ││  ← chip list; tap [+ Add]
│ └──────────────────────────┘│     opens a small ticker
│                              │     entry dialog, saved once,
│  Starting Capital            │     reused in every future
│  Rs [ 10,000 ]                │     Add Buy/Sell dropdown
│                              │
│  Appearance                  │
│  ( Dark ) ( Light )          │
│                              │
│  Currency        [ PKR ▾ ]   │
│                              │
│  Account                     │
│  you@email.com                │
│  [ Log Out ]                 │
└─────────────────────────────┘
```
- Favorite Stocks list feeds the ticker autocomplete everywhere else in the app — type once, select forever after.

### 3.5 Navigation Structure (Mobile)
Bottom Navigation Bar — 3 tabs: **Dashboard | Transactions | Settings**, with the ⊕ FAB living on the Transactions tab (also reachable via a long-press shortcut from Dashboard, optional).

---

## 4. DESKTOP APP — Screen Specifications

Desktop reuses every component and color/type token above, but arranged in a **persistent sidebar + multi-pane** layout suited to a mouse/keyboard, larger screen, and multitasking.

### 4.1 Overall Shell

```
┌───┬─────────────────────────────────────────────────┐
│ ▤ │  Dashboard                                       │
│───│                                                   │
│ 🏠│  (main content area — changes per nav item)       │
│Dash│                                                  │
│───│                                                   │
│ 📄│                                                   │
│Txn │                                                  │
│───│                                                   │
│ ⚙️│                                                   │
│Set │                                                   │
│───│                                                   │
│ 👤│  ← user avatar / logout, pinned bottom            │
└───┴─────────────────────────────────────────────────┘
```
- Persistent left rail (72px collapsed / 220px expanded, toggle with ▤).
- Keyboard shortcuts: `Ctrl+N` New Transaction, `Ctrl+F` Search, `Ctrl+,` Settings.

### 4.2 Dashboard (Desktop)

```
┌───┬─────────────────────────────────────────────────┐
│   │  Portfolio Overview                    [Aug 3 ▾]│
│   │  ┌───────────┬───────────┬───────────┬─────────┐│
│   │  │ Invested  │ Realized  │ Free Cash │ Open Lots││ ← 4-across
│   │  │ Rs 9,474  │ P/L 4,489 │ Rs 8,818  │    2     ││   StatCards
│   │  └───────────┴───────────┴───────────┴─────────┘│
│   │  ┌─────────────────────┬─────────────────────┐  │
│   │  │  Allocation (Donut) │  P/L Trend (Line)    │  │ ← two charts
│   │  │                     │                       │  │   side by side
│   │  └─────────────────────┴─────────────────────┘  │
│   │  Per-Stock Summary                    [+ Add ▾] │
│   │  ┌─────────────────────────────────────────────┐│
│   │  │Stock│Held│Invested│Avg Price│P/L  │Status   ││ ← sortable
│   │  │STPL │150 │Rs1,267 │Rs 8.45  │4,489│Partial  ││   DataTable
│   │  │BNL  │630 │Rs4,404 │Rs 6.99  │  -  │Open     ││   columns,
│   │  └─────────────────────────────────────────────┘│   click row →
│   │                                                   │   detail panel
└───┴─────────────────────────────────────────────────┘
```
- This table is the **direct visual descendant of the Excel "Per-Stock Summary"** — same columns, same information, but every cell is auto-computed with no formulas to maintain, and clicking a row opens the stock's full lot/sale breakdown in a slide-over panel on the right.

### 4.3 Transactions (Desktop) — Master-Detail Layout

```
┌───┬─────────────┬───────────────────────────────────┐
│   │ Lots         │  STPL · Bought Aug 3, 2026         │
│   │ ┌─────────┐  │  1800 shares @ Rs 8.45              │
│   │ │STPL 1800│◄─┼─ selected                            │
│   │ │Partial  │  │  Sale History                        │
│   │ ├─────────┤  │  ┌─────────────────────────────────┐│
│   │ │BNL  630 │  │  │Date      │Price │Qty │Received  ││
│   │ │Open     │  │  │Aug 5 '26 │10.18 │600 │Rs 6,108  ││
│   │ └─────────┘  │  │Aug 6 '26 │10.34 │600 │Rs 6,204  ││
│   │              │  │Jul 8 '26 │11.23 │450 │Rs 5,054  ││
│   │ [+ Add Lot]  │  │                                   │
│   │              │  │  150 shares remaining              │
│   │              │  │  [ + Add Sale ]                    │
└───┴─────────────┴───────────────────────────────────┘
```
- Left pane: scrollable lot list with search/filter toolbar above it.
- Right pane: selected lot's full detail + inline "Add Sale" — opens as an inline expanding row or a small modal, not a full-screen form (desktop has room to keep context visible).
- `Ctrl+N` or **[+ Add Lot]** opens the Add Buy modal (same fields as mobile, laid out in 2 columns instead of stacked).

### 4.4 Settings (Desktop)

```
┌───┬─────────────────────────────────────────────────┐
│   │  Settings                                         │
│   │  ┌───────────┐                                    │
│   │  │ Favorites │  ⭐ STPL  ⭐ BNL   [+ Add Ticker]  │
│   │  │ General   │                                    │
│   │  │ Account   │  (tabbed sub-sections, left mini-nav)│
│   │  └───────────┘                                    │
└───┴─────────────────────────────────────────────────┘
```
- Same functional content as mobile, organized into left-hand sub-tabs (Favorites / General / Account) since desktop has more horizontal room.

---

## 5. Motion & Micro-interaction Specification

| Interaction | Behavior | Duration/Easing |
|---|---|---|
| Onboarding chart draw-in | Path animates left→right | 1.6s, `easeOutCubic` |
| Donut chart segment sweep | Segments animate in sequence | 200ms/segment, `spring` |
| Dashboard number refresh | Old value counts up/down to new value | 400ms, `easeOut` |
| StockRow tap | Slight scale-down (0.97) then navigate | 100ms |
| FAB → Bottom Sheet | FAB morphs into sheet handle (Material shape morph) | 250ms |
| Add Sale validation error | Field shakes horizontally + red outline fade-in | 300ms |
| Status badge change (e.g., Partial→Closed) | Badge cross-fades color + brief scale pop | 250ms |

**Recommended packages:** `fl_chart` (all charts), `flutter_animate` (micro-interactions), `rive` or custom `CustomPainter` (onboarding illustrations), `flutter_staggered_animations` (list entrance animations on Dashboard/Transactions load).

---

## 6. Responsive & Adaptive Rules

| Breakpoint | Layout |
|---|---|
| < 600px (phone) | Single column, bottom nav, bottom sheets for forms |
| 600–1024px (tablet/small desktop) | Sidebar collapses to icon-only rail, 2-column dashboard grid |
| > 1024px (desktop) | Full sidebar, master-detail transactions view, 4-across StatCards |

Flutter implementation: single `LayoutBuilder`/`MediaQuery`-driven adaptive scaffold shared across targets — same screens, same widgets, different arrangement, per the design system in §2.

---

## 7. Accessibility

- Minimum tap target 44×44px (mobile), 32×32px (desktop with mouse precision).
- Color is never the *only* signal — every status badge carries a text label, not just a color.
- All StatCards and chart data points have semantic labels for screen readers (e.g., "Realized profit and loss, 4,489 rupees, positive").
- Supports OS-level text scaling up to 130% without layout breakage (tested at the "Numeric-Mono" and "Body" styles first, as they appear most densely).

---

## 8. Design Handoff Checklist

- [ ] Color tokens exported as Flutter `ThemeData`/`ColorScheme`
- [ ] Typography exported as `TextTheme`
- [ ] Icon set finalized (stock ticker avatars, nav icons, status icons)
- [ ] Onboarding animation asset (Rive file or CustomPainter path data)
- [ ] Chart library confirmed (`fl_chart`) and sample data wired
- [ ] Component library built as reusable widgets (StatCard, StockRow, StatusBadge, FavoriteChip)
- [ ] Adaptive scaffold breakpoints implemented and tested on all 5 target platforms
