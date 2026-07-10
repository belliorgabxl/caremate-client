import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class MembersPage extends StatefulWidget {
  const MembersPage({super.key});

  @override
  State<MembersPage> createState() => _MembersPageState();
}

class _MembersPageState extends State<MembersPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'ทั้งหมด';

  final List<_CareMember> _members = const [
    _CareMember(
      id: 'm1',
      name: 'ภัทรจาริน นภากาญจน์',
      nickname: 'Gabel',
      relationship: 'ตัวเอง',
      phone: '081-234-5678',
      age: 27,
      gender: 'ชาย',
      bloodType: 'O',
      isDefault: true,
      isSelf: true,
      color: Color(0xFF2CB7A0),
      icon: Icons.person,
      tags: ['ไม่มีโรคประจำตัว', 'แพ้ฝุ่น'],
      careNote: 'ดูแลทั่วไป สามารถเดินทางเองได้',
    ),
    _CareMember(
      id: 'm2',
      name: 'สมชาย นภากาญจน์',
      nickname: 'พ่อ',
      relationship: 'บิดา',
      phone: '089-111-2222',
      age: 64,
      gender: 'ชาย',
      bloodType: 'B',
      isDefault: false,
      isSelf: false,
      color: Color(0xFF5B8DEF),
      icon: Icons.elderly,
      tags: ['ความดัน', 'ต้องมีคนพยุง'],
      careNote: 'เดินช้า ต้องระวังตอนขึ้นลงรถ',
    ),
    _CareMember(
      id: 'm3',
      name: 'สมหญิง นภากาญจน์',
      nickname: 'แม่',
      relationship: 'มารดา',
      phone: '086-333-4444',
      age: 59,
      gender: 'หญิง',
      bloodType: 'A',
      isDefault: false,
      isSelf: false,
      color: Color(0xFFFF9F43),
      icon: Icons.favorite,
      tags: ['แพ้อาหารทะเล', 'ทานยาประจำ'],
      careNote: 'แจ้งเตือนให้ทานยาหลังอาหาร',
    ),
    _CareMember(
      id: 'm4',
      name: 'น้องมิน',
      nickname: 'มิน',
      relationship: 'น้องสาว',
      phone: '082-555-7777',
      age: 21,
      gender: 'หญิง',
      bloodType: 'AB',
      isDefault: false,
      isSelf: false,
      color: Color(0xFFB56EFF),
      icon: Icons.face_3,
      tags: ['สุขภาพแข็งแรง'],
      careNote: 'ไม่มีหมายเหตุพิเศษ',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_CareMember> get _filteredMembers {
    final keyword = _searchController.text.trim().toLowerCase();

    return _members.where((member) {
      final matchFilter = switch (_selectedFilter) {
        'ตัวเอง' => member.isSelf,
        'ครอบครัว' => !member.isSelf,
        'ค่าเริ่มต้น' => member.isDefault,
        _ => true,
      };

      final matchSearch = keyword.isEmpty ||
          member.name.toLowerCase().contains(keyword) ||
          member.nickname.toLowerCase().contains(keyword) ||
          member.relationship.toLowerCase().contains(keyword) ||
          member.phone.contains(keyword);

      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final members = _filteredMembers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            onPressed: _showMockInfo,
            icon: const Icon(Icons.info_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMemberSheet,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสมาชิก'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 18),
          _buildSummarySection(),
          const SizedBox(height: 18),
          _buildSearchBox(),
          const SizedBox(height: 14),
          _buildFilters(),
          const SizedBox(height: 18),
          Row(
            children: [
              const Text(
                'สมาชิกทั้งหมด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${members.length} คน',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (members.isEmpty)
            _buildEmptyState()
          else
            ...members.map(
                  (member) => Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _MemberCard(
                  member: member,
                  onTap: () => _showMemberDetail(member),
                  onBook: () => _mockBookForMember(member),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    final defaultMember = _members.firstWhere((member) => member.isDefault);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2CB7A0),
            Color(0xFF168B78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'Mock Mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'จัดการคนที่คุณดูแล',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'เลือกสมาชิกเพื่อจองบริการ ดูข้อมูลสุขภาพ หรือจัดการผู้ติดต่อฉุกเฉิน',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 14,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'ค่าเริ่มต้น: ${defaultMember.nickname} (${defaultMember.relationship})',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySection() {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: '${_members.length}',
            subtitle: 'สมาชิก',
            icon: Icons.people_alt_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '1',
            subtitle: 'ค่าเริ่มต้น',
            icon: Icons.star_rounded,
            color: const Color(0xFFFFB020),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: '3',
            subtitle: 'มีโน้ตดูแล',
            icon: Icons.medical_information_rounded,
            color: const Color(0xFF5B8DEF),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'ค้นหาชื่อ, ความสัมพันธ์ หรือเบอร์โทร',
        prefixIcon: const Icon(Icons.search),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
          onPressed: () {
            _searchController.clear();
            setState(() {});
          },
          icon: const Icon(Icons.close),
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildFilters() {
    final filters = ['ทั้งหมด', 'ตัวเอง', 'ครอบครัว', 'ค่าเริ่มต้น'];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((filter) {
          final selected = _selectedFilter == filter;

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(filter),
              selected: selected,
              showCheckmark: false,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: Colors.white,
              side: BorderSide(
                color: selected ? AppColors.primary : AppColors.border,
              ),
              onSelected: (_) {
                setState(() {
                  _selectedFilter = filter;
                });
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 52,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 12),
          Text(
            'ไม่พบสมาชิก',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'ลองเปลี่ยนคำค้นหาหรือตัวกรองอีกครั้ง',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  void _mockBookForMember(_CareMember member) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Mock: เริ่มจองบริการให้ ${member.nickname}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showMockInfo() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Members Mock'),
          content: const Text(
            'หน้านี้เป็น mock UI สำหรับทดสอบ flow สมาชิก ยังไม่ได้ต่อ API จริง',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('เข้าใจแล้ว'),
            ),
          ],
        );
      },
    );
  }

  void _showAddMemberSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.person_add_alt_1_rounded,
                size: 54,
                color: AppColors.primary,
              ),
              const SizedBox(height: 12),
              const Text(
                'เพิ่มสมาชิกใหม่',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Mock action: ใน step ถัดไปเราจะทำหน้า form สำหรับเพิ่ม พ่อ แม่ ญาติ หรือคนที่ต้องการดูแล',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mock: ไปหน้า Add Member ใน step ถัดไป'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('เริ่มเพิ่มสมาชิก'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showMemberDetail(_CareMember member) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: member.color.withValues(alpha: 0.16),
                child: Icon(
                  member.icon,
                  color: member.color,
                  size: 42,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                member.name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${member.relationship} • ${member.age} ปี • กรุ๊ปเลือด ${member.bloodType}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              _DetailRow(
                icon: Icons.phone_outlined,
                label: 'เบอร์โทร',
                value: member.phone,
              ),
              _DetailRow(
                icon: Icons.wc_rounded,
                label: 'เพศ',
                value: member.gender,
              ),
              _DetailRow(
                icon: Icons.note_alt_outlined,
                label: 'หมายเหตุการดูแล',
                value: member.careNote,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _mockBookForMember(member);
                  },
                  icon: const Icon(Icons.calendar_month),
                  label: Text('จองบริการให้ ${member.nickname}'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MemberCard extends StatelessWidget {
  const _MemberCard({
    required this.member,
    required this.onTap,
    required this.onBook,
  });

  final _CareMember member;
  final VoidCallback onTap;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Hero(
                    tag: 'member-${member.id}',
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: member.color.withValues(alpha: 0.14),
                      child: Icon(
                        member.icon,
                        color: member.color,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                member.nickname,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (member.isDefault) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB020)
                                      .withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.star_rounded,
                                      size: 14,
                                      color: Color(0xFFFFB020),
                                    ),
                                    SizedBox(width: 3),
                                    Text(
                                      'Default',
                                      style: TextStyle(
                                        color: Color(0xFFFFB020),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${member.relationship} • ${member.age} ปี • ${member.phone}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: member.tags.map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: member.color.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: member.color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.medical_information_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        member.careNote,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onTap,
                      icon: const Icon(Icons.visibility_outlined),
                      label: const Text('ดูข้อมูล'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onBook,
                      icon: const Icon(Icons.calendar_month),
                      label: const Text('จองบริการ'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CareMember {
  const _CareMember({
    required this.id,
    required this.name,
    required this.nickname,
    required this.relationship,
    required this.phone,
    required this.age,
    required this.gender,
    required this.bloodType,
    required this.isDefault,
    required this.isSelf,
    required this.color,
    required this.icon,
    required this.tags,
    required this.careNote,
  });

  final String id;
  final String name;
  final String nickname;
  final String relationship;
  final String phone;
  final int age;
  final String gender;
  final String bloodType;
  final bool isDefault;
  final bool isSelf;
  final Color color;
  final IconData icon;
  final List<String> tags;
  final String careNote;
}