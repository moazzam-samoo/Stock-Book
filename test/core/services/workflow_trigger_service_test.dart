import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stock_investment_tracker/core/services/workflow_trigger_service.dart';

/// Every distinguishable GitHub failure gets its own outcome and message —
/// "it didn't work" is precisely the failure mode that cost this project the
/// most debugging time, so a wrong token must not look like a network drop.
void main() {
  WorkflowTriggerService serviceReturning(int status) {
    return WorkflowTriggerService(
      client: MockClient((_) async => http.Response('', status)),
    );
  }

  group('WorkflowTriggerService.trigger', () {
    test('a 204 means the run was queued', () async {
      final result = await serviceReturning(204).trigger('tok');
      expect(result.outcome, WorkflowTriggerOutcome.queued);
      expect(result.isSuccess, isTrue);
    });

    test('401 is reported as a bad token, not a generic error', () async {
      final result = await serviceReturning(401).trigger('tok');
      expect(result.outcome, WorkflowTriggerOutcome.badToken);
      expect(result.isSuccess, isFalse);
    });

    test('403 is reported as missing Actions permission', () async {
      final result = await serviceReturning(403).trigger('tok');
      expect(result.outcome, WorkflowTriggerOutcome.forbidden);
    });

    test('404 is reported as repo/workflow not found', () async {
      final result = await serviceReturning(404).trigger('tok');
      expect(result.outcome, WorkflowTriggerOutcome.notFound);
    });

    test('an unexpected status preserves the code in the message', () async {
      final result = await serviceReturning(500).trigger('tok');
      expect(result.outcome, WorkflowTriggerOutcome.unknownError);
      expect(result.message, contains('500'));
    });

    test('a network failure is reported as such, never as a bad token', () async {
      final service = WorkflowTriggerService(
        client: MockClient((_) async => throw const _FakeSocketException()),
      );

      final result = await service.trigger('tok');

      expect(result.outcome, WorkflowTriggerOutcome.networkError);
    });

    test('no token short-circuits without any network call', () async {
      var called = false;
      final service = WorkflowTriggerService(
        client: MockClient((_) async {
          called = true;
          return http.Response('', 204);
        }),
      );

      final result = await service.trigger(null);

      expect(result.outcome, WorkflowTriggerOutcome.noToken);
      expect(called, isFalse, reason: 'must not hit GitHub with no credential');
    });

    test('a whitespace-only token counts as no token', () async {
      final result = await serviceReturning(204).trigger('   ');
      expect(result.outcome, WorkflowTriggerOutcome.noToken);
    });

    test('posts to the workflow dispatch endpoint with the main ref', () async {
      late http.Request captured;
      final service = WorkflowTriggerService(
        client: MockClient((req) async {
          captured = req;
          return http.Response('', 204);
        }),
      );

      await service.trigger('  tok  ');

      expect(captured.method, 'POST');
      expect(
        captured.url.toString(),
        'https://api.github.com/repos/${WorkflowTriggerService.owner}'
        '/${WorkflowTriggerService.repo}/actions/workflows'
        '/${WorkflowTriggerService.workflowFile}/dispatches',
      );
      // Scheduled runs only ever fire from the default branch, so an on-demand
      // run must target the same ref or it would run different code.
      expect(jsonDecode(captured.body), {'ref': 'main'});
      // The token is trimmed before use — a stray newline from a paste would
      // otherwise produce a confusing 401.
      expect(captured.headers['Authorization'], 'Bearer tok');
    });
  });
}

class _FakeSocketException implements Exception {
  const _FakeSocketException();
}
