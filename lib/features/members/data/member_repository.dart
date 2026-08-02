import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/models/care_member.dart';

class MaxRelativesReachedException implements Exception {
  const MaxRelativesReachedException();

  @override
  String toString() => 'สามารถเพิ่มสมาชิกที่ดูแลได้สูงสุด ${AppConfig.maxRelatives} คน';
}

class MemberRepository {
  MemberRepository(this._api);

  final ApiClient _api;

  Future<List<CareMember>> list() async {
    try {
      final response = await _api.dio.get('/user-relatives');
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      final relatives = data['relatives'] as List<dynamic>? ?? const [];

      return [
        for (var i = 0; i < relatives.length; i++)
          CareMember.fromJson(relatives[i] as Map<String, dynamic>, seq: i),
      ].where((m) => m.isActive).toList(growable: false);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<CareMember> create({
    required String fullName,
    required String nickname,
    required String relationship,
    required String phone,
    required int age,
    required String gender,
    required String bloodType,
    required String careNote,
  }) async {
    final current = await list();
    final activeRelatives = current.where((m) => !m.isSelf).length;
    if (activeRelatives >= AppConfig.maxRelatives) {
      throw const MaxRelativesReachedException();
    }

    final nameParts = fullName.trim().split(RegExp(r'\s+'));
    final now = DateTime.now();
    final approxDateOfBirth = DateTime(now.year - age, now.month, now.day);
    final dateOfBirthIso = approxDateOfBirth.toIso8601String().split('T').first;

    try {
      final response = await _api.dio.post('/user-relatives', data: {
        'firstName': nameParts.isNotEmpty ? nameParts.first : fullName,
        'lastName': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        'phone': phone,
        'email': null,
        'dateOfBirth': dateOfBirthIso,
        'gender': gender,
        'registerAs': null,
        'addressLine': null,
        'province': null,
        'emergencyContactName': null,
        'emergencyContactPhone': null,
        'careNote': careNote,
        'relationship': relationship,
        'isDefault': false,
      });
      final data = _api.unwrap(response.data) as Map<String, dynamic>;

      // `POST /user-relatives` (CreateUserRelativeRequest) has no nickname/
      // bloodType fields on the backend, and its dateOfBirth is accepted but
      // never persisted (repo bug) — only `PATCH` (UpdateUserRelativeRequest)
      // writes those columns, so a follow-up patch is required or they save
      // as NULL in `user_informations`.
      final createdId = data['id'] as String?;
      if (createdId != null) {
        await _api.dio.patch('/user-relatives/$createdId', data: {
          'nickname': nickname,
          'bloodType': bloodType,
          'dateOfBirth': dateOfBirthIso,
        });
      }

      return CareMember.fromJson(data, seq: current.length);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<void> update({
    required String id,
    required String fullName,
    required String nickname,
    required String relationship,
    required String phone,
    required int age,
    required String gender,
    required String bloodType,
    required String careNote,
  }) async {
    final nameParts = fullName.trim().split(RegExp(r'\s+'));
    final now = DateTime.now();
    final approxDateOfBirth = DateTime(now.year - age, now.month, now.day);

    try {
      await _api.dio.patch('/user-relatives/$id', data: {
        'firstName': nameParts.isNotEmpty ? nameParts.first : fullName,
        'lastName': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        'nickname': nickname,
        'relationship': relationship,
        'phone': phone,
        'dateOfBirth': approxDateOfBirth.toIso8601String().split('T').first,
        'gender': gender,
        'bloodType': bloodType,
        'careNote': careNote,
      });
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  /// Backend has no DELETE /user-relatives/{id} route yet — this will 404
  /// until it's added there.
  Future<void> softDelete(String id) async {
    try {
      await _api.dio.delete('/user-relatives/$id');
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<void> setDefault(String id) async {
    try {
      final detailResponse = await _api.dio.get('/user-relatives/$id');
      final unwrapped = _api.unwrap(detailResponse.data) as Map<String, dynamic>;
      final detail = (unwrapped['relative'] as Map<String, dynamic>?) ?? unwrapped;

      await _api.dio.patch('/user-relatives/$id', data: {
        'firstName': detail['firstName'],
        'lastName': detail['lastName'],
        'phone': detail['phone'],
        'email': detail['email'],
        'dateOfBirth': detail['dateOfBirth'],
        'gender': detail['gender'],
        'registerAs': null,
        'relationship': detail['relationship'],
        'addressLine': detail['addressLine'],
        'subdistrict': detail['subdistrict'],
        'district': detail['district'],
        'province': detail['province'],
        'latitude': (detail['latitude'] as num?)?.toDouble() ?? 0,
        'longitude': (detail['longitude'] as num?)?.toDouble() ?? 0,
        'postalCode': detail['postalCode'],
        'emergencyContactName': detail['emergencyContactName'],
        'emergencyContactPhone': detail['emergencyContactPhone'],
        'emergencyContactRelationship': detail['emergencyContactRelationship'],
        'bloodType': detail['bloodType'],
        'allergies': detail['allergies'],
        'congenitalDiseases': detail['congenitalDiseases'],
        'currentMedications': detail['currentMedications'],
        'careNote': detail['careNote'],
        'isDefault': true,
      });
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }
}

final memberRepositoryProvider = Provider<MemberRepository>((ref) {
  return MemberRepository(ref.read(apiClientProvider));
});
