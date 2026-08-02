import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/address.dart';
import '../../../shared/models/booking.dart';
import '../../../shared/models/care_member.dart';
import '../../../shared/models/care_service.dart';
import '../../../shared/models/mission.dart';
import '../../../shared/models/payment.dart';

/// Dart's `DateTime.toIso8601String()` omits the timezone entirely for local
/// (non-UTC) DateTimes (e.g. `2026-08-05T09:00:00.000`, no `Z`/offset) —
/// that's not valid RFC3339, and the backend's `time.Parse(time.RFC3339, ...)`
/// rejects it outright, so `scheduledAt`/`scheduledEndAt` need the offset
/// appended explicitly.
String _toRfc3339(DateTime dt) {
  if (dt.isUtc) return dt.toIso8601String();

  final offset = dt.timeZoneOffset;
  final sign = offset.isNegative ? '-' : '+';
  final hours = offset.abs().inHours.toString().padLeft(2, '0');
  final minutes = (offset.abs().inMinutes % 60).toString().padLeft(2, '0');
  return '${dt.toIso8601String()}$sign$hours:$minutes';
}

class BookingRepository {
  BookingRepository(this._api);

  final ApiClient _api;

  // Set right after createBooking() so the payment page can show the rich,
  // just-created booking without the /bookings list endpoint (which
  // doesn't carry service/member details) round-tripping data loss.
  Booking? _pendingBooking;
  Payment? _pendingPayment;

  Future<List<CareService>> getServices() async {
    try {
      final response = await _api.dio.get('/care/services');
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      final services = (data['services'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .where((s) => s['is_active'] as bool? ?? true)
          .toList(growable: false);

      return [
        for (var i = 0; i < services.length; i++) CareService.fromJson(services[i], seq: i),
      ];
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<List<Booking>> getAllBookings() async {
    try {
      final response = await _api.dio.get('/bookings/history');
      final items = _extractList(response.data, const ['bookings', 'history', 'items']);

      final bookings = [for (final item in items) Booking.fromJson(item as Map<String, dynamic>)];
      bookings.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
      return bookings;
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<List<Booking>> getActiveBookings() async {
    try {
      final response = await _api.dio.get('/bookings');
      final items = _extractList(response.data, const ['bookings']);

      return [for (final item in items) Booking.fromJson(item as Map<String, dynamic>)]
          .where(
            (b) =>
                b.status != BookingStatus.completed &&
                b.status != BookingStatus.cancelled &&
                b.status != BookingStatus.paymentExpired,
          )
          .toList(growable: false);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<Booking> createBooking({
    required CareService service,
    required CareMember member,
    required DateTime scheduledAt,
    required DateTime scheduledEndAt,
    required Address pickupAddress,
    Address? destinationAddress,
    String? notes,
    required String paymentMethodId,
  }) async {
    final includeDestination = service.requiresDestination && destinationAddress != null;

    try {
      final response = await _api.dio.post('/bookings/create', data: {
        'serviceTypeId': service.id,
        'paymentMethodId': paymentMethodId,
        'isForSelf': member.isSelf,
        'relativeId': member.isSelf ? null : member.id,
        'scheduledStartAt': _toRfc3339(scheduledAt),
        'scheduledEndAt': _toRfc3339(scheduledEndAt),
        'pickupAddress': pickupAddress.addressLine,
        'pickupLat': pickupAddress.latitude,
        'pickupLng': pickupAddress.longitude,
        if (includeDestination) 'destinationAddress': destinationAddress.addressLine,
        if (includeDestination) 'destinationLat': destinationAddress.latitude,
        if (includeDestination) 'destinationLng': destinationAddress.longitude,
        'contactName': member.fullName,
        'contactPhone': member.phone,
        'specialNotes': notes,
      });

      final data = _api.unwrap(response.data) as Map<String, dynamic>;

      final booking = Booking(
        id: data['bookingId'] as String? ?? '',
        reference: data['reference'] as String? ?? '',
        serviceTitle: service.title,
        serviceIcon: service.icon,
        serviceColor: service.color,
        memberName: member.fullName,
        scheduledAt: scheduledAt,
        pickupAddress: pickupAddress.addressLine,
        destinationAddress: includeDestination ? destinationAddress.addressLine : null,
        distanceKm: (data['distanceKm'] as num?)?.toDouble(),
        notes: notes,
        totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0,
        status: BookingStatusX.fromApi(data['status'] as String?),
        paymentId: data['paymentId'] as String?,
      );

      _pendingBooking = booking;
      _pendingPayment = Payment(
        id: data['paymentId'] as String? ?? '',
        bookingId: booking.id,
        paymentMethodId: paymentMethodId,
        totalAmount: booking.totalAmount,
        status: PaymentStatusX.fromApi(data['paymentStatus'] as String?),
        reference: booking.reference,
      );

      return booking;
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  /// Primary polling endpoint once payment is confirmed (see booking-flow.md
  /// §1, §5) — matching happens async on the backend, so this is the only
  /// way the client observes `booking.status` moving PENDING -> MATCHED ->
  /// IN_PROGRESS -> COMPLETED and picks up partner/mission details.
  Future<BookingMissionDetail> getMission(String bookingId) async {
    try {
      final response = await _api.dio.get('/bookings/$bookingId/mission');
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      final bookingJson = data['booking'] as Map<String, dynamic>? ?? const {};
      final missionJson = data['mission'] as Map<String, dynamic>?;
      final partnerJson = data['partner'] as Map<String, dynamic>?;

      return BookingMissionDetail(
        booking: Booking.fromJson(bookingJson),
        mission: missionJson == null ? null : Mission.fromJson(missionJson),
        partner: partnerJson == null ? null : Partner.fromJson(partnerJson),
      );
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  /// The booking+payment awaiting checkout: the one just created in this
  /// session if any, else whatever `/users/payment-check` reports (e.g.
  /// the user re-opened the app before paying).
  Future<(Booking, Payment)?> getPendingPayment() async {
    if (_pendingBooking != null && _pendingPayment != null) {
      return (_pendingBooking!, _pendingPayment!);
    }

    try {
      final response = await _api.dio.get('/users/payment-check');
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      if (data['hasPayment'] != true) return null;

      final items = data['items'] as List<dynamic>? ?? const [];
      if (items.isEmpty) return null;

      final item = items.first as Map<String, dynamic>;
      final bookingJson = item['booking'] as Map<String, dynamic>? ?? const {};
      final paymentJson = item['payment'] as Map<String, dynamic>? ?? const {};

      final scheduledRaw = pickField(bookingJson, const ['scheduled_at', 'scheduledAt']) as String?;
      final totalAmount = (pickField(paymentJson, const ['total_amount', 'totalAmount']) as num?)?.toDouble() ?? 0;

      final booking = Booking(
        id: bookingJson['id'] as String? ?? '',
        reference: bookingJson['reference'] as String? ?? '',
        memberName: (pickField(bookingJson, const ['patientName', 'patient_name']) as String?) ?? '-',
        scheduledAt: scheduledRaw == null ? DateTime.now() : DateTime.tryParse(scheduledRaw) ?? DateTime.now(),
        pickupAddress: '-',
        totalAmount: totalAmount,
        status: BookingStatus.awaitingPayment,
        paymentId: paymentJson['id'] as String?,
      );

      final payment = Payment(
        id: paymentJson['id'] as String? ?? '',
        bookingId: booking.id,
        paymentMethodId: '',
        totalAmount: totalAmount,
        status: PaymentStatus.pending,
        reference: booking.reference,
      );

      return (booking, payment);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  void clearPendingPayment() {
    _pendingBooking = null;
    _pendingPayment = null;
  }

  List<dynamic> _extractList(dynamic body, List<String> keys) {
    final unwrapped = _api.unwrap(body);
    if (unwrapped is List) return unwrapped;
    if (unwrapped is Map<String, dynamic>) {
      for (final key in keys) {
        final value = unwrapped[key];
        if (value is List) return value;
      }
    }
    return const [];
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository(ref.read(apiClientProvider));
});
