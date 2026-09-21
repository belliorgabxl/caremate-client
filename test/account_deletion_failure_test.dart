import 'package:client_app/core/network/api_client.dart';
import 'package:client_app/features/profile/presentation/account_deletion_failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AccountDeletionFailure.from', () {
    test('401 means the session is gone, so the UI should sign out', () {
      final f = AccountDeletionFailure.from(
        const ApiException('unauthorized', statusCode: 401),
      );

      expect(f.sessionExpired, isTrue);
      expect(f.offerSupport, isFalse);
    });

    test('409 with an active booking tells the user to wait, no support link', () {
      final f = AccountDeletionFailure.from(
        const ApiException(
          'cannot delete account while a booking is still in progress',
          statusCode: 409,
          code: 'ACCOUNT_DELETE_ACTIVE_BOOKING',
        ),
      );

      expect(f.message, contains('รายการจองที่ยังดำเนินอยู่'));
      expect(f.offerSupport, isFalse);
      expect(f.sessionExpired, isFalse);
    });

    test('409 with a pending refund sends the user to support', () {
      final f = AccountDeletionFailure.from(
        const ApiException(
          'cannot delete account while a refund is still pending',
          statusCode: 409,
          code: 'ACCOUNT_DELETE_REFUND_PENDING',
        ),
      );

      expect(f.message, contains('รอคืนเงิน'));
      expect(f.offerSupport, isTrue);
    });

    test('an unrecognised 409 still gets a Thai message and support link', () {
      for (final code in [null, 'SOMETHING_NEW']) {
        final f = AccountDeletionFailure.from(
          ApiException('blocked', statusCode: 409, code: code),
        );

        expect(f.message, isNot(contains('blocked')));
        expect(f.offerSupport, isTrue, reason: 'code=$code');
      }
    });

    test('never shows raw backend text for other failures', () {
      final f = AccountDeletionFailure.from(
        const ApiException('pq: relation "users" does not exist', statusCode: 500),
      );

      expect(f.message, isNot(contains('pq:')));
      expect(f.offerSupport, isFalse);
      expect(f.sessionExpired, isFalse);
    });

    test('a network failure (no status code) gets the connectivity message', () {
      final f = AccountDeletionFailure.from(
        const ApiException('connection timeout'),
      );

      expect(f.message, contains('อินเทอร์เน็ต'));
    });

    test('a non-API error (a bug, not the server) still yields a message', () {
      final f = AccountDeletionFailure.from(StateError('boom'));

      expect(f.message, isNotEmpty);
      expect(f.sessionExpired, isFalse);
    });
  });
}
