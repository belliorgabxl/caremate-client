import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import 'address.dart';

const _memberIcons = [
  Icons.person,
  Icons.elderly,
  Icons.favorite,
  Icons.child_care,
  Icons.face,
];

class CareMember {
  const CareMember({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.nickname,
    required this.relationship,
    required this.phone,
    required this.age,
    required this.gender,
    required this.bloodType,
    required this.isDefault,
    required this.isSelf,
    required this.isActive,
    required this.color,
    required this.icon,
    required this.tags,
    required this.careNote,
    required this.address,
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.emergencyContactRelationship = '',
  });

  final String id;
  final String firstName;
  final String lastName;
  final String nickname;
  final String relationship;
  final String phone;
  final int age;
  final String gender;
  final String bloodType;
  final bool isDefault;
  final bool isSelf;
  final bool isActive;
  final Color color;
  final IconData icon;
  final List<String> tags;
  final String careNote;
  final Address address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final String emergencyContactRelationship;

  /// Display-only join of the two stored name parts — the backend keeps
  /// `firstName`/`lastName` separate and so do we, so a name with a space in
  /// it (e.g. a two-word given name) never gets re-split on the way back.
  String get fullName => '$firstName $lastName'.trim();

  /// Maps a backend `RelativeMember`/`RelativeByIDMember` JSON object. The
  /// backend has no concept of a display color/icon/tags — those stay
  /// client-side presentational touches, assigned deterministically by seq.
  factory CareMember.fromJson(Map<String, dynamic> json, {int seq = 0}) {
    var firstName = (json['firstName'] as String? ?? '').trim();
    var lastName = (json['lastName'] as String? ?? '').trim();
    // Only endpoints that return a pre-joined `fullName` (and no name parts)
    // need splitting — the split is a last resort, not the normal path.
    if (firstName.isEmpty && lastName.isEmpty) {
      final fullName = (json['fullName'] as String? ?? '').trim();
      if (fullName.isNotEmpty) {
        final parts = fullName.split(RegExp(r'\s+'));
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }
    final relationship = json['relationship'] as String? ?? '';
    final registerAs = json['registerAs'] as String? ?? '';
    final isSelf = registerAs.toLowerCase() == 'self' || relationship == 'ตัวเอง';

    final addressLine = json['addressLine'] as String? ?? '';
    final latitude = (json['latitude'] as num?)?.toDouble();
    final longitude = (json['longitude'] as num?)?.toDouble();

    final dobRaw = json['dateOfBirth'] as String?;
    final dob = dobRaw == null || dobRaw.isEmpty ? null : DateTime.tryParse(dobRaw);
    final age = dob == null ? 0 : (DateTime.now().difference(dob).inDays / 365.25).floor();

    final allergies = json['allergies'] as String? ?? '';
    final congenitalDiseases = json['congenitalDiseases'] as String? ?? '';
    final tags = [allergies, congenitalDiseases].where((t) => t.isNotEmpty).toList();

    return CareMember(
      id: json['id'] as String? ?? '',
      firstName: firstName,
      lastName: lastName,
      nickname: (json['nickname'] as String?)?.trim().isNotEmpty == true
          ? json['nickname'] as String
          : (firstName.isNotEmpty ? firstName : lastName),
      relationship: relationship,
      phone: json['phone'] as String? ?? '',
      age: age,
      gender: json['gender'] as String? ?? '',
      bloodType: json['bloodType'] as String? ?? '',
      isDefault: json['isDefault'] as bool? ?? false,
      isSelf: isSelf,
      isActive: json['isActive'] as bool? ?? true,
      color: AppColors.serviceColors[seq % AppColors.serviceColors.length],
      icon: isSelf ? Icons.person : _memberIcons[seq % _memberIcons.length],
      tags: tags,
      careNote: json['careNote'] as String? ?? '',
      address: Address(addressLine: addressLine, latitude: latitude, longitude: longitude),
      emergencyContactName: json['emergencyContactName'] as String? ?? '',
      emergencyContactPhone: json['emergencyContactPhone'] as String? ?? '',
      emergencyContactRelationship: json['emergencyContactRelationship'] as String? ?? '',
    );
  }

  CareMember copyWith({
    String? firstName,
    String? lastName,
    String? nickname,
    String? relationship,
    String? phone,
    int? age,
    String? gender,
    String? bloodType,
    bool? isDefault,
    bool? isActive,
    List<String>? tags,
    String? careNote,
    Address? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
  }) {
    return CareMember(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      nickname: nickname ?? this.nickname,
      relationship: relationship ?? this.relationship,
      phone: phone ?? this.phone,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      isDefault: isDefault ?? this.isDefault,
      isSelf: isSelf,
      isActive: isActive ?? this.isActive,
      color: color,
      icon: icon,
      tags: tags ?? this.tags,
      careNote: careNote ?? this.careNote,
      address: address ?? this.address,
      emergencyContactName: emergencyContactName ?? this.emergencyContactName,
      emergencyContactPhone: emergencyContactPhone ?? this.emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship ?? this.emergencyContactRelationship,
    );
  }
}
