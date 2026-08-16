import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/booking.dart' show pickField;

/// `GET /users/referral` response — the user's own referral code plus how
/// many people have signed up using it so far.
class ReferralInfo {
  const ReferralInfo({required this.code, required this.totalReferred});

  final String code;
  final int totalReferred;

  factory ReferralInfo.fromJson(Map<String, dynamic> json) {
    return ReferralInfo(
      code: (pickField(json, const ['code', 'referralCode']) as String?) ?? '',
      totalReferred:
          (pickField(json, const ['totalReferred', 'total_referred']) as num?)?.toInt() ?? 0,
    );
  }
}

class ReferralRepository {
  ReferralRepository(this._api);

  final ApiClient _api;

  Future<ReferralInfo> getReferral() async {
    try {
      final response = await _api.dio.get('/users/referral');
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      return ReferralInfo.fromJson(data);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }
}

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  return ReferralRepository(ref.read(apiClientProvider));
});
