import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/models/address.dart';
import '../../../shared/models/care_member.dart';

class MaxRelativesReachedException implements Exception {
  const MaxRelativesReachedException();

  @override
  String toString() => 'สามารถเพิ่มสมาชิกที่ดูแลได้สูงสุด ${AppConfig.maxRelatives} คน';
}

class MemberRepository {
  final List<CareMember> _members = [
    const CareMember(
      id: 'm1',
      fullName: 'ภัทรจาริน นภากาญจน์',
      nickname: 'Gabel',
      relationship: 'ตัวเอง',
      phone: '081-234-5678',
      age: 27,
      gender: 'ชาย',
      bloodType: 'O',
      isDefault: true,
      isSelf: true,
      isActive: true,
      color: AppColors.primary,
      icon: Icons.person,
      tags: ['ไม่มีโรคประจำตัว', 'แพ้ฝุ่น'],
      careNote: 'ดูแลทั่วไป สามารถเดินทางเองได้',
      address: Address(addressLine: 'คอนโด CareMate Residence, ถนนสุขุมวิท'),
    ),
    const CareMember(
      id: 'm2',
      fullName: 'สมชาย นภากาญจน์',
      nickname: 'พ่อ',
      relationship: 'บิดา',
      phone: '089-111-2222',
      age: 64,
      gender: 'ชาย',
      bloodType: 'B',
      isDefault: false,
      isSelf: false,
      isActive: true,
      color: AppColors.serviceHomeCare,
      icon: Icons.elderly,
      tags: ['ความดัน', 'ต้องมีคนพยุง'],
      careNote: 'เดินช้า ต้องระวังตอนขึ้นลงรถ',
      address: Address(addressLine: 'คอนโด CareMate Residence, ถนนสุขุมวิท'),
    ),
    const CareMember(
      id: 'm3',
      fullName: 'สมหญิง นภากาญจน์',
      nickname: 'แม่',
      relationship: 'มารดา',
      phone: '086-333-4444',
      age: 59,
      gender: 'หญิง',
      bloodType: 'A',
      isDefault: false,
      isSelf: false,
      isActive: true,
      color: AppColors.serviceMedication,
      icon: Icons.favorite,
      tags: ['แพ้อาหารทะเล', 'ทานยาประจำ'],
      careNote: 'แจ้งเตือนให้ทานยาหลังอาหาร',
      address: Address(addressLine: 'คอนโด CareMate Residence, ถนนสุขุมวิท'),
    ),
  ];

  Future<List<CareMember>> list() async {
    await Future.delayed(AppConfig.mockNetworkDelay);
    return _members.where((m) => m.isActive).toList(growable: false);
  }

  CareMember? getById(String id) {
    for (final member in _members) {
      if (member.id == id) return member;
    }
    return null;
  }

  Future<CareMember> getSelf() async {
    await Future.delayed(AppConfig.mockNetworkDelay);
    return _members.firstWhere((m) => m.isSelf);
  }

  Future<CareMember> updateDetails(
    String id, {
    String? fullName,
    String? nickname,
    String? phone,
    int? age,
    String? gender,
    String? bloodType,
    List<String>? tags,
    String? careNote,
    Address? address,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
  }) async {
    await Future.delayed(AppConfig.mockNetworkDelay);

    final index = _members.indexWhere((m) => m.id == id);
    if (index == -1) throw StateError('ไม่พบข้อมูลสมาชิก');

    final updated = _members[index].copyWith(
      fullName: fullName,
      nickname: nickname,
      phone: phone,
      age: age,
      gender: gender,
      bloodType: bloodType,
      tags: tags,
      careNote: careNote,
      address: address,
      emergencyContactName: emergencyContactName,
      emergencyContactPhone: emergencyContactPhone,
      emergencyContactRelationship: emergencyContactRelationship,
    );
    _members[index] = updated;
    return updated;
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
    await Future.delayed(AppConfig.mockNetworkDelay);

    final activeRelatives = _members.where((m) => !m.isSelf && m.isActive).length;
    if (activeRelatives >= AppConfig.maxRelatives) {
      throw const MaxRelativesReachedException();
    }

    final colors = AppColors.serviceColors;
    final member = CareMember(
      id: 'm-${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName,
      nickname: nickname,
      relationship: relationship,
      phone: phone,
      age: age,
      gender: gender,
      bloodType: bloodType,
      isDefault: false,
      isSelf: false,
      isActive: true,
      color: colors[_members.length % colors.length],
      icon: Icons.person_outline_rounded,
      tags: const [],
      careNote: careNote,
      address: const Address(addressLine: ''),
    );

    _members.add(member);
    return member;
  }

  Future<void> softDelete(String id) async {
    await Future.delayed(AppConfig.mockNetworkDelay);

    final index = _members.indexWhere((m) => m.id == id);
    if (index == -1) return;

    final removed = _members[index];
    _members[index] = removed.copyWith(isActive: false, isDefault: false);

    if (removed.isDefault) {
      final selfIndex = _members.indexWhere((m) => m.isSelf);
      if (selfIndex != -1) {
        _members[selfIndex] = _members[selfIndex].copyWith(isDefault: true);
      }
    }
  }

  Future<void> setDefault(String id) async {
    await Future.delayed(AppConfig.mockNetworkDelay);

    for (var i = 0; i < _members.length; i++) {
      _members[i] = _members[i].copyWith(isDefault: _members[i].id == id);
    }
  }
}

final memberRepositoryProvider = Provider<MemberRepository>((ref) => MemberRepository());
