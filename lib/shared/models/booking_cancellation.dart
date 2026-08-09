import 'booking.dart';

/// Error codes returned by `POST /bookings/:id/cancel`. The same HTTP 409
/// covers two very different outcomes (already cancelled = effectively a
/// success, not cancellable = a real dead end), so callers must branch on
/// the code, never on the status alone.
abstract final class BookingCancelErrorCode {
  static const alreadyCancelled = 'BOOKING_ALREADY_CANCELLED';
  static const notCancellable = 'BOOKING_NOT_CANCELLABLE';
  static const notFound = 'BOOKING_NOT_FOUND';
  static const invalidRequest = 'INVALID_BOOKING_REQUEST';
}

/// `POST /bookings/:bookingID/cancel` response payload. Field casing is
/// camelCase here (same as `POST /bookings/create`, unlike the snake_case
/// list endpoints).
class BookingCancellation {
  const BookingCancellation({
    required this.bookingId,
    required this.reference,
    required this.previousStatus,
    required this.cancelledAt,
    required this.cancelledBy,
    required this.refundRequired,
    this.reason,
    this.paymentId,
    this.paymentStatus,
  });

  final String bookingId;
  final String reference;

  /// Status the booking was in immediately before cancelling — drives which
  /// wording the user sees (a MATCHED booking means a partner was already
  /// assigned and has now been notified).
  final BookingStatus previousStatus;
  final DateTime? cancelledAt;
  final String cancelledBy;

  /// True when the booking was already paid, so money has to come back. There
  /// is no automated refund yet — the back-office does it by hand.
  final bool refundRequired;
  final String? reason;
  final String? paymentId;

  /// Raw payment status after cancelling: `CANCELLED` when cancelled before
  /// paying, `PAID` when cancelled after.
  final String? paymentStatus;

  factory BookingCancellation.fromJson(Map<String, dynamic> json) {
    final cancelledAtRaw = json['cancelledAt'] as String?;

    return BookingCancellation(
      bookingId: json['bookingId'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      previousStatus: BookingStatusX.fromApi(json['previousStatus'] as String?),
      cancelledAt: cancelledAtRaw == null ? null : DateTime.tryParse(cancelledAtRaw),
      cancelledBy: json['cancelledBy'] as String? ?? 'user',
      refundRequired: json['refundRequired'] as bool? ?? false,
      reason: (json['reason'] as String?)?.trim().isEmpty == true ? null : json['reason'] as String?,
      paymentId: json['paymentId'] as String?,
      paymentStatus: json['paymentStatus'] as String?,
    );
  }
}
