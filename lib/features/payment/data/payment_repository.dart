import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/payment.dart';

class PaymentNotFoundException implements Exception {
  const PaymentNotFoundException();

  @override
  String toString() => 'ไม่พบรายการชำระเงิน';
}

class PaymentRepository {
  final List<PaymentMethod> methods = const [
    PaymentMethod(
      id: 'card',
      title: 'บัตรเครดิต/เดบิต',
      subtitle: 'Visa, Mastercard, JCB',
      icon: Icons.credit_card_rounded,
    ),
    PaymentMethod(
      id: 'promptpay',
      title: 'พร้อมเพย์ (PromptPay)',
      subtitle: 'สแกน QR เพื่อชำระเงิน',
      icon: Icons.qr_code_rounded,
    ),
    PaymentMethod(
      id: 'cash',
      title: 'เงินสด (จ่ายกับพาร์ทเนอร์)',
      subtitle: 'ชำระเมื่อได้รับบริการ',
      icon: Icons.payments_rounded,
    ),
    PaymentMethod(
      id: 'truemoney',
      title: 'TrueMoney Wallet',
      subtitle: 'เชื่อมต่อบัญชี TrueMoney',
      icon: Icons.account_balance_wallet_rounded,
    ),
  ];

  final List<Payment> _payments = [];

  Future<List<PaymentMethod>> getMethods() async {
    await Future.delayed(AppConfig.mockNetworkDelay);
    return methods;
  }

  Payment createForBooking({
    required String bookingId,
    required double totalAmount,
    required String paymentMethodId,
  }) {
    final payment = Payment(
      id: 'pay-${DateTime.now().millisecondsSinceEpoch}',
      bookingId: bookingId,
      paymentMethodId: paymentMethodId,
      totalAmount: totalAmount,
      status: PaymentStatus.pending,
      reference: 'CM${DateTime.now().millisecondsSinceEpoch.toRadixString(36).toUpperCase()}',
      expiredAt: DateTime.now().add(const Duration(minutes: 15)),
    );
    _payments.add(payment);
    return payment;
  }

  Future<Payment> getById(String id) async {
    await Future.delayed(AppConfig.mockNetworkDelay);
    for (final payment in _payments) {
      if (payment.id == id) return payment;
    }
    throw const PaymentNotFoundException();
  }

  Future<Payment> confirm(String id) async {
    await Future.delayed(AppConfig.mockNetworkDelay);

    final index = _payments.indexWhere((p) => p.id == id);
    if (index == -1) throw const PaymentNotFoundException();

    final confirmed = _payments[index].copyWith(status: PaymentStatus.paid, paidAt: DateTime.now());
    _payments[index] = confirmed;
    return confirmed;
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) => PaymentRepository());
