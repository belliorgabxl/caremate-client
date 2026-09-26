import 'address.dart';

class UserProfile {
  const UserProfile({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    this.dateOfBirth,
    this.gender = '',
    this.bloodType = '',
    this.allergies = '',
    this.congenitalDiseases = '',
    this.currentMedications = '',
    this.careNote = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelationship = '',
    this.address,
  });

  final String userId;
  final String firstName;
  final String lastName;
  final String phone;
  final String email;
  final DateTime? dateOfBirth;
  final String gender;
  final String bloodType;
  final String allergies;
  final String congenitalDiseases;
  final String currentMedications;
  final String careNote;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelationship;
  final Address? address;

  String get fullName => '$firstName $lastName'.trim();

  /// Merges `/api/auth/me` (personal info), `/api/user/health-information`,
  /// and `/api/user/address` into the single profile shape the UI works with.
  factory UserProfile.fromApi({
    required Map<String, dynamic> me,
    Map<String, dynamic>? health,
    Map<String, dynamic>? address,
  }) {
    final info = me['information'] as Map<String, dynamic>?;
    final nameParts = (me['name'] as String? ?? '').trim().split(
      RegExp(r'\s+'),
    );

    final addressLine = address?['address_line'] as String?;

    return UserProfile(
      userId: me['id'] as String? ?? '',
      firstName: (info?['firstName'] as String?)?.trim().isNotEmpty == true
          ? info!['firstName'] as String
          : (nameParts.isNotEmpty ? nameParts.first : ''),
      lastName: (info?['lastName'] as String?)?.trim().isNotEmpty == true
          ? info!['lastName'] as String
          : (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : ''),
      phone: me['phone'] as String? ?? '',
      email: info?['email'] as String? ?? '',
      dateOfBirth: _parseDate(info?['dateOfBirth'] as String?),
      gender: info?['gender'] as String? ?? '',
      bloodType: health?['blood_type'] as String? ?? '',
      allergies: health?['allergies'] as String? ?? '',
      congenitalDiseases: health?['congenital_diseases'] as String? ?? '',
      currentMedications: health?['current_medications'] as String? ?? '',
      careNote: health?['care_note'] as String? ?? '',
      emergencyContactName: health?['emergency_contact_name'] as String? ?? '',
      emergencyContactPhone:
          health?['emergency_contact_phone'] as String? ?? '',
      emergencyContactRelationship:
          health?['emergency_contact_relationship'] as String? ?? '',
      address: (addressLine == null || addressLine.isEmpty)
          ? null
          : Address(
              addressLine: addressLine,
              latitude: (address?['latitude'] as num?)?.toDouble(),
              longitude: (address?['longitude'] as num?)?.toDouble(),
            ),
    );
  }

  static DateTime? _parseDate(String? value) {
    if (value == null || value.isEmpty) return null;
    return DateTime.tryParse(value);
  }

  Map<String, dynamic> toPersonalInformationJson() => {
    'firstName': firstName,
    'lastName': lastName,
    'phone': phone,
    'dateOfBirth': dateOfBirth == null
        ? ''
        : dateOfBirth!.toIso8601String().split('T').first,
    'gender': gender,
    'email': email,
  };

  Map<String, dynamic> toHealthInformationJson() => {
    'emergency_contact_name': emergencyContactName,
    'emergency_contact_phone': emergencyContactPhone,
    'emergency_contact_relationship': emergencyContactRelationship,
    'blood_type': bloodType,
    'allergies': allergies,
    'congenital_diseases': congenitalDiseases,
    'current_medications': currentMedications,
    'care_note': careNote,
  };

  /// Null when there's no address to persist yet — callers should skip the
  /// PATCH call in that case rather than send an empty/invalid address.
  Map<String, dynamic>? toAddressJson() {
    final a = address;
    if (a == null || !a.hasCoordinates) return null;

    return {
      'address_line': a.addressLine,
      'subdistrict': '',
      'district': '',
      'province': '',
      'postal_code': '',
      'latitude': a.latitude,
      'longitude': a.longitude,
    };
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    DateTime? dateOfBirth,
    String? gender,
    String? bloodType,
    String? allergies,
    String? congenitalDiseases,
    String? currentMedications,
    String? careNote,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
    Address? address,
  }) {
    return UserProfile(
      userId: userId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      congenitalDiseases: congenitalDiseases ?? this.congenitalDiseases,
      currentMedications: currentMedications ?? this.currentMedications,
      careNote: careNote ?? this.careNote,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone:
          emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship:
          emergencyContactRelationship ?? this.emergencyContactRelationship,
      address: address ?? this.address,
    );
  }
}
