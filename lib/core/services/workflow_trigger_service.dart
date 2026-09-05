import 'dart:convert';

import 'package:http/http.dart' as http;

/// Why a trigger attempt ended the way it did.
///
/// Deliberately specific: "it didn't work" is the failure mode that cost this
/// project the most time, so every distinguishable cause gets its own case and
/// its own message rather than collapsing into a generic error.
enum WorkflowTriggerOutcome {
  /// GitHub accepted the dispatch (HTTP 204). The run itself still takes
  /// roughly a minute — success here means "queued", not "prices updated".
  queued,

  /// No token has been saved on this device yet.
  noToken,

  /// 401 — the token is wrong, expired, or was revoked.
  badToken,

  /// 403 — the token is valid but lacks Actions write permission on this
  /// repo (the usual cause: a fine-grained token missing the "Actions"
  /// permission, or not granted access to this repository).
  forbidden,

  /// 404 — repo or workflow file not found under this token's access. Also
  /// what GitHub returns when a fine-grained token can't see the repo at all.
  notFound,

  /// Network unreachable, DNS failure, timeout.
  networkError,

  /// Anything else, with the status code preserved for the message.
  unknownError,
}

class WorkflowTriggerResult {
  final WorkflowTriggerOutcome outcome;
  final int? statusCode;

  const WorkflowTriggerResult(this.outcome, {this.statusCode});

  bool get isSuccess => outcome == WorkflowTriggerOutcome.queued;

  /// A message safe and useful to show the user directly.
  String get message {
    switch (outcome) {
      case WorkflowTriggerOutcome.queued:
        return 'Fetching latest prices — updates in about a minute.';
      case WorkflowTriggerOutcome.noToken:
        return 'Add a GitHub token in Settings to refresh prices on demand.';
      case WorkflowTriggerOutcome.badToken:
        return 'GitHub rejected the token. Check it in Settings.';
      case WorkflowTriggerOutcome.forbidden:
        return 'Token lacks Actions permission for this repository.';
      case WorkflowTriggerOutcome.notFound:
        return 'Repository or workflow not found for this token.';
      case WorkflowTriggerOutcome.networkError:
        return "Couldn't reach GitHub. Check your connection.";
      case WorkflowTriggerOutcome.unknownError:
        return 'GitHub returned an unexpected error${statusCode != null ? ' ($statusCode)' : ''}.';
    }
  }
}

/// Triggers the price-alerts GitHub Actions workflow on demand.
///
/// The workflow already runs on a schedule; this exists for the case the
/// schedule can't cover — outside market hours, on weekends, or right after
/// adding a holding, when waiting up to five minutes (or until Monday) for a
/// price isn't acceptable.
///
/// The token is never stored here, in the repo, or in the built APK — it is
/// passed in per call from device-only secure storage. See
/// [SecureTokenStorage].
class WorkflowTriggerService {
  static const String owner = 'moazzam-samoo';
  static const String repo = 'Stock-Book';

  /// The workflow's filename doubles as its API id.
  static const String workflowFile = 'price-alerts.yml';

  /// Scheduled runs only ever fire from the default branch, so an on-demand
  /// run targets the same ref — otherwise a manual refresh could silently run
  /// different code than the schedule does.
  static const String ref = 'main';

  final http.Client _client;

  WorkflowTriggerService({http.Client? client}) : _client = client ?? http.Client();

  Future<WorkflowTriggerResult> trigger(String? token) async {
    if (token == null || token.trim().isEmpty) {
      return const WorkflowTriggerResult(WorkflowTriggerOutcome.noToken);
    }

    final uri = Uri.https(
      'api.github.com',
      '/repos/$owner/$repo/actions/workflows/$workflowFile/dispatches',
    );

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Accept': 'application/vnd.github+json',
              'Authorization': 'Bearer ${token.trim()}',
              'X-GitHub-Api-Version': '2022-11-28',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'ref': ref}),
          )
          .timeout(const Duration(seconds: 10));

      switch (response.statusCode) {
        case 204:
          return const WorkflowTriggerResult(WorkflowTriggerOutcome.queued, statusCode: 204);
        case 401:
          return const WorkflowTriggerResult(WorkflowTriggerOutcome.badToken, statusCode: 401);
        case 403:
          return const WorkflowTriggerResult(WorkflowTriggerOutcome.forbidden, statusCode: 403);
        case 404:
          return const WorkflowTriggerResult(WorkflowTriggerOutcome.notFound, statusCode: 404);
        default:
          return WorkflowTriggerResult(
            WorkflowTriggerOutcome.unknownError,
            statusCode: response.statusCode,
          );
      }
    } catch (_) {
      // Timeout, socket failure, DNS — all indistinguishable to the user and
      // all fixed the same way, so they share one outcome.
      return const WorkflowTriggerResult(WorkflowTriggerOutcome.networkError);
    }
  }
}
