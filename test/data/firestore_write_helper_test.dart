import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:stock_investment_tracker/data/data_sources/remote/firestore_data_source.dart';

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

void main() {
  group('FirestoreDataSource _write helper', () {
    late FirestoreDataSource dataSource;

    setUp(() {
      dataSource = FirestoreDataSource(MockFirebaseFirestore());
    });

    test('completes normally when op succeeds', () async {
      var executed = false;
      await expectLater(
        dataSource.writeWithTimeoutGuard(() async {
          executed = true;
        }, 'testOp'),
        completes,
      );
      expect(executed, isTrue);
    });

    test('swallows TimeoutException (allowing local persistence queue)', () async {
      await expectLater(
        dataSource.writeWithTimeoutGuard(() async {
          throw TimeoutException('Timed out waiting for server ack');
        }, 'testOp'),
        completes,
      );
    });

    test('swallows retryable FirebaseExceptions (unavailable, deadline-exceeded, aborted, cancelled)', () async {
      final retryableCodes = ['unavailable', 'deadline-exceeded', 'aborted', 'cancelled'];

      for (final code in retryableCodes) {
        await expectLater(
          dataSource.writeWithTimeoutGuard(() async {
            throw FirebaseException(plugin: 'cloud_firestore', code: code);
          }, 'testOp'),
          completes,
          reason: 'Expected $code to be swallowed as retryable',
        );
      }
    });

    test('rethrows non-retryable FirebaseExceptions (permission-denied, unauthenticated)', () async {
      final fatalCodes = ['permission-denied', 'unauthenticated', 'resource-exhausted'];

      for (final code in fatalCodes) {
        expect(
          () => dataSource.writeWithTimeoutGuard(() async {
            throw FirebaseException(plugin: 'cloud_firestore', code: code);
          }, 'testOp'),
          throwsA(isA<FirebaseException>().having((e) => e.code, 'code', code)),
          reason: 'Expected $code to be rethrown to caller',
        );
      }
    });

    test('rethrows unexpected non-Firebase errors', () async {
      expect(
        () => dataSource.writeWithTimeoutGuard(() async {
          throw StateError('Invalid state');
        }, 'testOp'),
        throwsStateError,
      );
    });
  });
}

