import 'package:flutter/material.dart';

enum PaymentStatus { pending, paid, expired }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.pending => 'รอชำระ',
        PaymentStatus.paid => 'ชำระแล้ว',
        PaymentStatus.expired => 'หมดอายุ',
      };
}

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
}

class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.paymentMethodId,
    required this.totalAmount,
    required this.status,
    required this.reference,
    required this.expiredAt,
    this.paidAt,
  });

  final String id;
  final String bookingId;
  final String paymentMethodId;
  final double totalAmount;
  final PaymentStatus status;
  final String reference;
  final DateTime expiredAt;
  final DateTime? paidAt;

  Payment copyWith({PaymentStatus? status, DateTime? paidAt}) {
    return Payment(
      id: id,
      bookingId: bookingId,
      paymentMethodId: paymentMethodId,
      totalAmount: totalAmount,
      status: status ?? this.status,
      reference: reference,
      expiredAt: expiredAt,
      paidAt: paidAt ?? this.paidAt,
    );
  }
}
