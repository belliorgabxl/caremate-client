import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/charge_info.dart';
import '../../../shared/models/payment.dart';

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
          if (method['is_active'] as bool? ?? true)
            PaymentMethod.fromJson(method),
      ];
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<Payment> getById(String id) async {
    try {
      final response = await _api.dio.get(
        '/payments/${Uri.encodeComponent(id)}',
      );
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      return Payment.fromJson(data);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  /// Creates (or, if one already exists and hasn't expired, returns the
  /// already-created) a real Beam QR PromptPay charge for a pending payment.
  /// This never marks the payment paid — only Beam's webhook does that
  /// server-side. Safe to call again (e.g. on a page reload); it won't
  /// create a second charge.
  Future<ChargeInfo> createCharge({required String paymentId}) async {
    try {
      final response = await _api.dio.post(
        '/payments/${Uri.encodeComponent(paymentId)}/charge',
      );
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      return ChargeInfo.fromJson(data);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.read(apiClientProvider));
});
