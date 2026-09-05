import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/workflow_trigger_service.dart';
import '../data/data_sources/local/secure_token_storage.dart';

final secureTokenStorageProvider = Provider<SecureTokenStorage>((ref) {
  return SecureTokenStorage();
});

final workflowTriggerServiceProvider = Provider<WorkflowTriggerService>((ref) {
  return WorkflowTriggerService();
});

/// Whether a GitHub token is currently saved on this device — drives the
/// Settings UI's saved/not-saved state.
final hasGithubTokenProvider = FutureProvider<bool>((ref) async {
  return ref.watch(secureTokenStorageProvider).hasGithubToken();
});

/// Reads the stored token and asks GitHub to run the price-alerts workflow.
///
/// Returns a [WorkflowTriggerResult] rather than throwing, so every caller
/// (pull-to-refresh, the Settings test button) reports the same precise
/// reason for failure instead of a generic one.
final triggerWorkflowProvider = Provider<Future<WorkflowTriggerResult> Function()>((ref) {
  return () async {
    final token = await ref.read(secureTokenStorageProvider).readGithubToken();
    return ref.read(workflowTriggerServiceProvider).trigger(token);
  };
});
