/// Outcome of `SettingsRepository.togglePin` — typed so the UI can show the
/// right message instead of a generic error, mirroring `WorkflowTriggerResult`
/// (`core/services/workflow_trigger_service.dart`).
enum PinResult {
  pinned,
  unpinned,

  /// Free-tier cap (5 pinned tickers) reached while trying to pin a new one.
  /// Nothing was written — the caller's `pinnedTickers` is unchanged.
  limitReached,
}
