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
      await _api.dio.patch('/users/personal-information', data: profile.toPersonalInformationJson());
      await _api.dio.patch('/users/health-information', data: profile.toHealthInformationJson());

      final addressJson = profile.toAddressJson();
      if (addressJson != null) {
        await _api.dio.patch('/users/address', data: addressJson);
      }

      return profile;
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(apiClientProvider));
});
