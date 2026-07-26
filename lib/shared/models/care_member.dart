import 'package:flutter/material.dart';

import 'address.dart';

class CareMember {
  const CareMember({
    required this.id,
    required this.fullName,
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
  final String fullName;
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

  CareMember copyWith({
    String? fullName,
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
      fullName: fullName ?? this.fullName,
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
