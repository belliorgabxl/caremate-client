import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/user_profile.dart';
import '../../auth/data/models/app_user.dart';

class ProfileRepository {
  ProfileRepository(this._api);

  final ApiClient _api;

  Future<UserProfile> getForUser(AppUser user) async {
    try {
      final meResponse = await _api.dio.get('/authentication/me');
      final me = _api.unwrap(meResponse.data) as Map<String, dynamic>;

      Map<String, dynamic>? health;
      try {
        final healthResponse = await _api.dio.get('/users/health-information');
        health = _api.unwrap(healthResponse.data) as Map<String, dynamic>?;
      } on DioException {
        health = null;
      }

      Map<String, dynamic>? address;
      try {
        final addressResponse = await _api.dio.get('/users/address');
        address = _api.unwrap(addressResponse.data) as Map<String, dynamic>?;
      } on DioException {
        address = null;
      }

      return UserProfile.fromApi(me: me, health: health, address: address);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<UserProfile> update(UserProfile profile) async {
    try {
      await _api.dio.patch(
        '/users/personal-information',
        data: profile.toPersonalInformationJson(),
      );
      await _api.dio.patch(
        '/users/health-information',
        data: profile.toHealthInformationJson(),
      );

      final addressJson = profile.toAddressJson();
      if (addressJson != null) {
        await _api.dio.patch('/users/address', data: addressJson);
      }

      return profile;
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  /// Used as a booking gate — a customer must have a bank account on file
  /// before booking, so finance has somewhere to send a manual refund if
  /// Beam can't refund the original charge automatically.
  Future<bool> hasBankAccount() async {
    try {
      final response = await _api.dio.get('/users/bank-account');
      final data = _api.unwrap(response.data) as Map<String, dynamic>?;
      return data?['has_bank_account'] as bool? ?? false;
    } on DioException catch (e) {
      // No user_informations row yet (first login, address/health never
      // saved either) reads as 404 — same as "no bank account yet".
      if (e.response?.statusCode == 404) return false;
      _api.throwApiException(e);
    }
  }

  Future<void> saveBankAccount({
    required String bankName,
    required String bankAccount,
    required String bankAccountName,
  }) async {
    try {
      await _api.dio.patch(
        '/users/bank-account',
        data: {
          'bank_name': bankName,
          'bank_account': bankAccount,
          'bank_account_name': bankAccountName,
        },
      );
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(apiClientProvider));
});
