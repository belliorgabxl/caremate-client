import 'package:flutter/material.dart';

enum PaymentStatus { pending, paid, expired }

extension PaymentStatusX on PaymentStatus {
  String get label => switch (this) {
        PaymentStatus.pending => 'รอชำระ',
        PaymentStatus.paid => 'ชำระแล้ว',
        PaymentStatus.expired => 'หมดอายุ',
      };

  static PaymentStatus fromApi(String? value) => switch (value) {
        'PAID' => PaymentStatus.paid,
        'EXPIRED' => PaymentStatus.expired,
        _ => PaymentStatus.pending,
      };
}

// Keyed by the real `icon_name` values from `GET /payments/methods`
// (confirmed against the live backend), with the slug as a fallback key.
const _paymentMethodIcons = {
  'qr-code': Icons.qr_code_rounded,
  'credit-card': Icons.credit_card_rounded,
  'banknotes': Icons.payments_rounded,
  'qr_promptpay': Icons.qr_code_rounded,
  'credit_card': Icons.credit_card_rounded,
  'cash': Icons.payments_rounded,
};

class PaymentMethod {
  const PaymentMethod({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final IconData icon;

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    final slug = json['slug'] as String? ?? '';

    return PaymentMethod(
      id: json['id'] as String? ?? '',
      slug: slug,
      title: json['name_th'] as String? ?? json['name_en'] as String? ?? slug,
      subtitle: json['name_en'] as String? ?? '',
      icon: _paymentMethodIcons[json['icon_name'] as String? ?? slug] ?? Icons.payment_rounded,
    );
  }
}

class Payment {
  const Payment({
    required this.id,
    required this.bookingId,
    required this.paymentMethodId,
    required this.totalAmount,
    required this.status,
    required this.reference,
    this.expiredAt,
    this.paidAt,
  });

  final String id;
  final String bookingId;
  final String paymentMethodId;
  final double totalAmount;
  final PaymentStatus status;
  final String reference;
  final DateTime? expiredAt;
  final DateTime? paidAt;

  /// Maps `PaymentDetail` from `GET /api/payment/[paymentId]`.
  factory Payment.fromJson(Map<String, dynamic> json) {
    final expiredRaw = json['expired_at'] as String?;
    final paidRaw = json['paid_at'] as String?;

    return Payment(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      paymentMethodId: json['payment_method_id'] as String? ?? '',
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0,
      status: PaymentStatusX.fromApi(json['status'] as String?),
      reference: json['reference'] as String? ?? '',
      expiredAt: expiredRaw == null ? null : DateTime.tryParse(expiredRaw),
      paidAt: paidRaw == null ? null : DateTime.tryParse(paidRaw),
    );
  }

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
