import '../../../core/network/api_client.dart';
import '../../../core/utils/error_messages.dart';

// `code` values of a 409 from DELETE /users/account — care-mate-backend
// internal/handler/user_handler.go.
const _activeBookingCode = 'ACCOUNT_DELETE_ACTIVE_BOOKING';
const _refundPendingCode = 'ACCOUNT_DELETE_REFUND_PENDING';

/// What to tell the user when deleting their account fails, and what the UI
/// should offer next. Kept free of widgets so the mapping is unit-testable.
class AccountDeletionFailure {
  const AccountDeletionFailure({
    required this.message,
    this.offerSupport = false,
    this.sessionExpired = false,
  });

  final String message;

  /// The blocker can't be cleared from inside the app (e.g. a refund only
  /// support can finish) — the UI should link to the help center.
  final bool offerSupport;

  /// The login is no longer valid; signing out is the only useful next step.
  final bool sessionExpired;

  factory AccountDeletionFailure.from(Object error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        return const AccountDeletionFailure(
          message: 'เซสชันหมดอายุ กรุณาเข้าสู่ระบบใหม่อีกครั้ง',
          sessionExpired: true,
        );
      }
      if (error.statusCode == 409) {
        if (error.code == _activeBookingCode) {
          return const AccountDeletionFailure(
            message:
                'ยังลบบัญชีไม่ได้ เพราะมีรายการจองที่ยังดำเนินอยู่ '
                'กรุณารอให้รายการเสร็จสิ้นหรือยกเลิกรายการนั้นก่อน',
          );
        }
        if (error.code == _refundPendingCode) {
          return const AccountDeletionFailure(
            message:
                'ยังลบบัญชีไม่ได้ เพราะมีรายการที่ชำระเงินแล้วและรอคืนเงิน '
                'กรุณาติดต่อฝ่ายสนับสนุนเพื่อดำเนินการคืนเงินก่อน',
            offerSupport: true,
          );
        }
        return const AccountDeletionFailure(
          message: 'ยังลบบัญชีไม่ได้ในขณะนี้ กรุณาติดต่อฝ่ายสนับสนุน',
          offerSupport: true,
        );
      }
    }
    return AccountDeletionFailure(message: friendlyErrorMessage(error));
  }
}
