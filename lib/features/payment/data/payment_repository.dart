import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/payment.dart';
import 'promptpay_qr.dart';

class PaymentRepository {
  PaymentRepository(this._api);

  final ApiClient _api;

  Future<List<PaymentMethod>> getMethods() async {
    try {
      final response = await _api.dio.get('/payments/methods');
      final data = _api.unwrap(response.data);
      final methods = data is List ? data : const [];

      return [
        for (final method in methods.cast<Map<String, dynamic>>())
          if (method['is_active'] as bool? ?? true) PaymentMethod.fromJson(method),
      ];
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<Payment> getById(String id) async {
    try {
      final response = await _api.dio.get('/payments/${Uri.encodeComponent(id)}');
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      return Payment.fromJson(data);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<Payment> confirm({required String bookingId, required String paymentId}) async {
    try {
      await _api.dio.post('/payments/confirm', data: {'bookingId': bookingId, 'paymentId': paymentId});
      final payment = await getById(paymentId);
      return payment.status == PaymentStatus.paid ? payment : payment.copyWith(status: PaymentStatus.paid, paidAt: DateTime.now());
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  /// Generates the raw PromptPay EMV QR payload string to render (e.g. with
  /// `QrImageView`), not an image itself. There's no backend endpoint for
  /// this — it's computed locally the same way caremate-client's Next.js
  /// proxy used to (see `promptpay_qr.dart`).
  String getPromptPayQrPayload({required double amount}) {
    return generatePromptPayPayload(promptPayId: AppConfig.promptPayId, amount: amount);
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(apiClientProvider));
});
