# Phase 09 — Searchable ticker picker

> Read [../AGENTS.md](../AGENTS.md) and [README.md](README.md) before starting. The universal agent
> rules in README.md apply in full.

**Depends on:** Phase 08's Task 7 (`tickers/all`) · **Estimated:** 1 day · **Branch:** `feat/positions-and-alerts`

Every ticker-entry field in this app — Favorites, buy/sell transactions, buy alerts (Phase 07) — is
free-text today. The user must already know and correctly type the exact PSX symbol from memory.
`TickerAutocomplete` only suggests from the user's own Favorites list, which is empty of exactly the
tickers a buy alert is meant for (you don't set a buy alert on something you already hold or already
favorited). This phase makes the full PSX ticker universe searchable, by name or symbol.

---

## Background — why this isn't a live "search the internet" box

PSX's full list of listed companies is small (a few hundred symbols) and changes rarely — a new
listing or delisting, not something that needs a network call per keystroke. Phase 08's Task 7 already
writes this list to a single Firestore document, `tickers/all`, refreshed at most once a day. This
phase's job is entirely client-side: fetch that document, cache it locally so search works offline and
instantly, and widen ticker entry to search it.

**Do not add a new live/paid ticker-search API.** The data already exists in Firestore by the time this
phase starts.

---

## Task 1 — Entity → model → repository → provider

Mirror the established chain (AGENTS.md §13), but this is reference data, not a live stream:

- `lib/domain/entities/ticker_info.dart` — `symbol`, `name`, `sector` (nullable)
- `lib/data/models/ticker_info_model.dart` (`@freezed`)
- `FirestorePaths.tickersDoc()` → `'tickers/all'`
- `TickerRepository` — `Future<List<TickerInfo>> getAll({bool forceRefresh = false})`, not a stream:
  this is read-once-per-session reference data, not something to watch live
- `tickerRepositoryProvider` — nullable, gated on `currentUserIdProvider` like every other repository

`firestore.rules` needs no change — Phase 08's Task 7 already added the `tickers/{doc}` read rule.

---

## Task 2 — Local cache

Follow `HiveDataSource`'s existing `market_prices_cache` pattern exactly (`saveMarketPrices`/
`getMarketPrices` in `hive_data_source.dart`) — same `_sanitizeMap` handling for Hive's
`Map<dynamic, dynamic>` quirk, same shape:

- `saveTickers(List<TickerInfoModel>)` / `getTickers()` in a new `tickers_cache` box
- `TickerRepositoryImpl.getAll()`: try Firestore first (`.timeout(4s)`, the established idiom); on
  success, write through to the Hive cache; on failure or timeout, fall back to whatever is cached.
  On a completely fresh install with no cache and no network, return an empty list — callers must
  already treat "no suggestions" as a safe, non-crashing state, since typing a ticker manually has
  always been possible and must stay possible.

---

## Task 3 — Widen `TickerAutocomplete`

`ticker_autocomplete.dart` currently searches only `settings.favorites`. Change its `optionsBuilder` to
search the full cached ticker list instead, matching against **both** `symbol` and `name`
(case-insensitive `contains`), so typing "united bank" finds `UBL`. Show the matched company name
under the symbol in each suggestion row (the existing `ListTile` already has room via a `subtitle`).

**Keep Favorites relevant, don't drop them**: when the full list has loaded, sort matches so any ticker
already in `settings.favorites` appears first among the results, rather than plain alphabetical/API
order. If the full list hasn't loaded yet (no cache, first launch, offline) fall back to searching
Favorites only, exactly like today — never show a blank dropdown with no explanation while the ticker
the user is typing might still be one of their favorites.

This widget is shared by Favorites-adding, buy/sell transactions, and Phase 07's buy alerts — fixing it
once fixes ticker entry everywhere. Do not fork a second copy for alerts.

---

## Required tests

| # | Test | Asserts |
|---|---|---|
| 1 | Searching by symbol substring | matches, case-insensitive |
| 2 | Searching by company name substring | matches, case-insensitive |
| 3 | A favorited ticker among the matches | sorted first |
| 4 | No full list loaded yet (cache empty, no network) | falls back to Favorites-only search, no crash |
| 5 | Firestore fetch fails | falls back to the Hive cache, not an empty list, if a cache exists |
| 6 | Model round-trip | `TickerInfoModel` serialises correctly, `sector: null` survives |
| 7 | Hive cache round-trip | mirrors the existing `market_prices_cache` test's shape |
| 8 | Widget: typing a company name in the Add Alert sheet | selecting a result fills the ticker field |

---

## Acceptance criteria

- [ ] `flutter analyze` — 0 errors; `flutter test` fully green
- [ ] With Phase 08's Task 7 deployed and `tickers/all` populated: typing a company name anywhere
      `TickerAutocomplete` is used returns the matching symbol
- [ ] Offline, with a previously-cached list: search still works
- [ ] Offline, on a fresh install with no cache: typing still works as free text, no crash, no
      infinite spinner

## Out of scope

Editing/managing the ticker list itself (that's Phase 08's scrape). Autocomplete for anything other
than ticker symbols. Any change to how Favorites are stored.
