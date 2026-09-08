/// Outcome of `SettingsRepository.redeemPremiumCode` — each failure mode
/// needs its own message rather than collapsing into a generic error,
/// mirroring `WorkflowTriggerResult` (`core/services/workflow_trigger_service.dart`).
enum PremiumCodeOutcome {
  /// The code existed, was unredeemed, and is now marked redeemed by this
  /// user. `isPremiumUnlocked` is now `true`.
  success,

  /// No `premium_codes/{code}` document exists with that exact ID.
  invalidCode,

  /// The code exists but `redeemed` was already `true` (used by someone
  /// else, or by this same user previously).
  alreadyRedeemed,

  /// The read or the redeem write failed for a reason unrelated to the code
  /// itself (offline, timeout, permission-denied from a rules mismatch).
  networkError,
}

class PremiumCodeResult {
  const PremiumCodeResult(this.outcome);

  final PremiumCodeOutcome outcome;

  /// A message safe and useful to show the user directly.
  String get message {
    switch (outcome) {
      case PremiumCodeOutcome.success:
        return "Unlocked! You can now pin unlimited stocks.";
      case PremiumCodeOutcome.invalidCode:
        return "That code doesn't exist. Double-check it and try again.";
      case PremiumCodeOutcome.alreadyRedeemed:
        return "That code has already been used.";
      case PremiumCodeOutcome.networkError:
        return "Couldn't reach the server — check your connection and try again.";
    }
  }
}
