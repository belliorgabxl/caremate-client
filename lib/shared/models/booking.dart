import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

enum BookingStatus {
  awaitingPayment,
  pending,
  matched,
  inProgress,
  completed,
  cancelled,
  paymentExpired,
}

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
    BookingStatus.awaitingPayment => 'รอชำระเงิน',
    BookingStatus.pending => 'กำลังหาผู้ดูแล',
    BookingStatus.matched => 'จับคู่แล้ว',
    BookingStatus.inProgress => 'กำลังดำเนินการ',
    BookingStatus.completed => 'เสร็จสิ้น',
    BookingStatus.cancelled => 'ยกเลิกแล้ว',
    BookingStatus.paymentExpired => 'หมดอายุการชำระ',
  };

  Color get color => switch (this) {
    BookingStatus.awaitingPayment => const Color(0xFFD97706),
    BookingStatus.pending => const Color(0xFF5B6B6A),
    BookingStatus.matched => const Color(0xFF2563EB),
    BookingStatus.inProgress => const Color(0xFF0F766E),
    BookingStatus.completed => const Color(0xFF16A34A),
    BookingStatus.cancelled => const Color(0xFFDC2626),
    BookingStatus.paymentExpired => const Color(0xFF9333EA),
  };

  /// Mirrors the backend's `IsBookingCancellableByUser` — `IN_PROGRESS` is
  /// deliberately excluded (a partner is already working the mission; that
  /// cancellation has to go through support), as are the terminal states.
  bool get isCancellableByUser => switch (this) {
    BookingStatus.awaitingPayment ||
    BookingStatus.pending ||
    BookingStatus.matched => true,
    _ => false,
  };

  static BookingStatus fromApi(String? value) => switch (value) {
    'AWAITING_PAYMENT' => BookingStatus.awaitingPayment,
    'PENDING' => BookingStatus.pending,
    'MATCHED' => BookingStatus.matched,
    'IN_PROGRESS' => BookingStatus.inProgress,
    'COMPLETED' => BookingStatus.completed,
    'CANCELLED' => BookingStatus.cancelled,
    'PAYMENT_EXPIRED' => BookingStatus.paymentExpired,
    _ => BookingStatus.pending,
  };
}

/// Reads the first present key — the backend mixes snake_case and camelCase
/// for the same logical field across booking endpoints.
dynamic pickField(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value;
  }
  return null;
}

class Booking {
  const Booking({
    required this.id,
    required this.reference,
    this.serviceTitle = 'บริการดูแลสุขภาพ',
    this.serviceIcon = Icons.medical_services_rounded,
    this.serviceColor = AppColors.primary,
    required this.memberName,
    required this.scheduledAt,
    required this.pickupAddress,
    this.destinationAddress,
    this.distanceKm,
    this.notes,
    required this.totalAmount,
    required this.status,
    this.paymentId,
  });

  final String id;
  final String reference;
  final String serviceTitle;
  final IconData serviceIcon;
  final Color serviceColor;
  final String memberName;
  final DateTime scheduledAt;
  final String pickupAddress;
  final String? destinationAddress;
  final double? distanceKm;
  final String? notes;
  final double totalAmount;
  final BookingStatus status;
  final String? paymentId;

  /// Maps `/api/booking/me` (`BookingItem`) and `/api/booking/history`
  /// (`RawBookingHistoryItem`) rows — both dual-cased, neither carries the
  /// service catalog entry or a paymentId (see [BookingRepository] for how
  /// the just-created booking keeps its richer client-known data instead).
  factory Booking.fromJson(Map<String, dynamic> json) {
    final scheduledRaw =
        pickField(json, ['scheduled_at', 'scheduledAt']) as String?;
    final scheduledAt = scheduledRaw == null
        ? DateTime.now()
        : DateTime.tryParse(scheduledRaw) ?? DateTime.now();

    return Booking(
      id: json['id'] as String? ?? '',
      reference: json['reference'] as String? ?? '',
      serviceTitle:
          (pickField(json, [
                'serviceTypeName',
                'service_type_name',
                'serviceName',
                'service_name',
              ])
              as String?) ??
          'บริการดูแลสุขภาพ',
      memberName:
          (pickField(json, [
                'patientName',
                'patient_name',
                'careReceiverName',
                'care_receiver_name',
              ])
              as String?) ??
          (pickField(json, ['contactName', 'contact_name']) as String?) ??
          '-',
      scheduledAt: scheduledAt,
      pickupAddress:
          (pickField(json, ['pickup_address', 'pickupAddress']) as String?) ??
          '-',
      destinationAddress:
          pickField(json, ['destination_address', 'destinationAddress'])
              as String?,
      totalAmount:
          (pickField(json, ['total_amount', 'totalAmount', 'fee']) as num?)
              ?.toDouble() ??
          0,
      status: BookingStatusX.fromApi(json['status'] as String?),
    );
  }

  Booking copyWith({BookingStatus? status}) {
    return Booking(
      id: id,
      reference: reference,
      serviceTitle: serviceTitle,
      serviceIcon: serviceIcon,
      serviceColor: serviceColor,
      memberName: memberName,
      scheduledAt: scheduledAt,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      distanceKm: distanceKm,
      notes: notes,
      totalAmount: totalAmount,
      status: status ?? this.status,
      paymentId: paymentId,
    );
  }
}
