import 'package:flutter/material.dart';

enum BookingStatus { awaitingPayment, pending, matched, inProgress, completed, cancelled }

extension BookingStatusX on BookingStatus {
  String get label => switch (this) {
        BookingStatus.awaitingPayment => 'รอชำระเงิน',
        BookingStatus.pending => 'กำลังหาผู้ดูแล',
        BookingStatus.matched => 'จับคู่แล้ว',
        BookingStatus.inProgress => 'กำลังดำเนินการ',
        BookingStatus.completed => 'เสร็จสิ้น',
        BookingStatus.cancelled => 'ยกเลิกแล้ว',
      };

  Color get color => switch (this) {
        BookingStatus.awaitingPayment => const Color(0xFFD97706),
        BookingStatus.pending => const Color(0xFF5B6B6A),
        BookingStatus.matched => const Color(0xFF2563EB),
        BookingStatus.inProgress => const Color(0xFF0F766E),
        BookingStatus.completed => const Color(0xFF16A34A),
        BookingStatus.cancelled => const Color(0xFFDC2626),
      };
}

class Booking {
  const Booking({
    required this.id,
    required this.reference,
    required this.serviceId,
    required this.serviceTitle,
    required this.serviceIcon,
    required this.serviceColor,
    required this.memberId,
    required this.memberName,
    required this.memberRelationship,
    required this.scheduledAt,
    required this.pickupAddress,
    this.destinationAddress,
    this.distanceKm,
    this.notes,
    required this.serviceFee,
    required this.platformFee,
    required this.status,
    required this.paymentId,
  });

  final String id;
  final String reference;
  final String serviceId;
  final String serviceTitle;
  final IconData serviceIcon;
  final Color serviceColor;
  final String memberId;
  final String memberName;
  final String memberRelationship;
  final DateTime scheduledAt;
  final String pickupAddress;
  final String? destinationAddress;
  final double? distanceKm;
  final String? notes;
  final double serviceFee;
  final double platformFee;
  final BookingStatus status;
  final String paymentId;

  double get totalAmount => serviceFee + platformFee;

  Booking copyWith({BookingStatus? status}) {
    return Booking(
      id: id,
      reference: reference,
      serviceId: serviceId,
      serviceTitle: serviceTitle,
      serviceIcon: serviceIcon,
      serviceColor: serviceColor,
      memberId: memberId,
      memberName: memberName,
      memberRelationship: memberRelationship,
      scheduledAt: scheduledAt,
      pickupAddress: pickupAddress,
      destinationAddress: destinationAddress,
      distanceKm: distanceKm,
      notes: notes,
      serviceFee: serviceFee,
      platformFee: platformFee,
      status: status ?? this.status,
      paymentId: paymentId,
    );
  }
}
