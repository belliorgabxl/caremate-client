// Tidewater members list — the page's one "peak" surface is a solid
// primary→primaryDark gradient hero (matching HomePage's `_HomeHeroCard`),
// with counts on a white card overlapping its bottom edge. Stat tiles and
// member rows stay plain solid cards; see DESIGN.md.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/members_dirty.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/care_member.dart';
import '../../../../shared/utils/confirm_dialogs.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../data/member_repository.dart';

class MembersPage extends ConsumerStatefulWidget {
  const MembersPage({super.key});

  @override
  ConsumerState<MembersPage> createState() => _MembersPageState();
}

const _genderOptions = [
  ('male', 'ชาย'),
  ('female', 'หญิง'),
  ('unspecified', 'ไม่ระบุ'),
];

const _bloodTypeOptions = ['A', 'B', 'AB', 'O'];

String _genderLabel(String value) {
  for (final option in _genderOptions) {
    if (option.$1 == value) return option.$2;
  }
  return value;
}

class _MembersPageState extends ConsumerState<MembersPage> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'ทั้งหมด';

  bool _isLoading = true;
  String? _error;
  List<CareMember> _members = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final members = await ref.read(memberRepositoryProvider).list();
      if (!mounted) return;
      setState(() {
        _members = members;
        _isLoading = false;
      });
      // Tells BookingPage (kept alive across tab switches by
      // StatefulShellRoute.indexedStack) its own member list may be stale —
      // see members_dirty.dart.
      membersDirty.value = true;
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = friendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CareMember> get _filteredMembers {
    final keyword = _searchController.text.trim().toLowerCase();

    return _members.where((member) {
      final matchFilter = switch (_selectedFilter) {
        'ตัวเอง' => member.isSelf,
        'ครอบครัว' => !member.isSelf,
        'ค่าเริ่มต้น' => member.isDefault,
        _ => true,
      };

      final matchSearch =
          keyword.isEmpty ||
          member.fullName.toLowerCase().contains(keyword) ||
          member.nickname.toLowerCase().contains(keyword) ||
          member.relationship.toLowerCase().contains(keyword) ||
          member.phone.contains(keyword);

      return matchFilter && matchSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: SafeArea(child: SizedBox.shrink()));
    }

    if (_error != null) {
      return Scaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
            children: [
              EmptyState(
                icon: Icons.error_outline_rounded,
                title: 'โหลดข้อมูลไม่สำเร็จ',
                message: _error!,
                action: PrimaryButton(
                  label: 'ลองอีกครั้ง',
                  icon: Icons.refresh_rounded,
                  expanded: false,
                  onPressed: _load,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final members = _filteredMembers;
    final textTheme = Theme.of(context).textTheme;
    final atMaxRelatives = _members.length >= AppConfig.maxRelatives;

    return Scaffold(
      floatingActionButton: atMaxRelatives
          ? FloatingActionButton.extended(
              onPressed: null,
              backgroundColor: AppColors.textSecondary.withValues(alpha: 0.4),
              icon: const Icon(Icons.block_rounded),
              label: Text('ถึงจำนวนสูงสุด (${AppConfig.maxRelatives} คน)'),
            )
          : FloatingActionButton.extended(
              onPressed: () => _showMemberFormSheet(),
              icon: const Icon(Icons.add),
              label: const Text('เพิ่มสมาชิก'),
            ),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuroraBackground(),
          ),
          RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 12,
                20,
                110,
              ),
              children: [
                _buildHeroCard(),
                const SizedBox(height: 6),
                _buildSearchBox(),
                const SizedBox(height: 14),
                _buildFilters(),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text('สมาชิกทั้งหมด', style: textTheme.titleLarge),
                    const SizedBox(width: 8),
                    StatusBadge(
                      text: '${members.length} คน',
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (members.isEmpty)
                  const EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'ไม่พบสมาชิก',
                    message: 'ลองเปลี่ยนคำค้นหาหรือตัวกรองอีกครั้ง',
                  )
                else
                  ...members.map(
                    (member) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _MemberCard(
                        member: member,
                        onTap: () => _showMemberDetail(member),
                        onSetDefault: member.isDefault
                            ? null
                            : () => _setDefault(member),
                        onDelete: member.isSelf
                            ? null
                            : () => _confirmDelete(member),
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

  /// Same composed-hero language as `HomePage`'s `_HomeHeroCard`: a deep
  /// teal→ink gradient card for the page intent (+ the default-member
  /// banner, when one exists) with the at-a-glance counts on a separate
  /// white card overlapping its bottom edge — one designed unit instead of
  /// a glass hero stacked above three separate same-shape `StatCard`s.
  Widget _buildHeroCard() {
    final defaultMember = _members.where((m) => m.isDefault).isEmpty
        ? null
        : _members.firstWhere((member) => member.isDefault);
    final textTheme = Theme.of(context).textTheme;
    final withNotes = _members
        .where((m) => m.careNote.trim().isNotEmpty)
        .length;
    final atMax = _members.length >= AppConfig.maxRelatives;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 40),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary, AppColors.primaryDark],
            ),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryDark.withValues(alpha: 0.32),
                offset: const Offset(0, 14),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    child: const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'จัดการคนที่คุณดูแล',
                          style: textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'เลือกสมาชิกเพื่อจองบริการ ดูข้อมูลสุขภาพ หรือจัดการผู้ติดต่อฉุกเฉิน',
                          style: textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (defaultMember != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.white),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'ค่าเริ่มต้น: ${defaultMember.nickname} (${defaultMember.relationship})',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -26),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: AppCard(
              elevated: true,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _MemberStatItem(
                      icon: Icons.people_alt_rounded,
                      color: AppColors.primary,
                      value: '${_members.length}',
                      label: 'สมาชิก',
                    ),
                  ),
                  const _MemberStatDivider(),
                  Expanded(
                    child: _MemberStatItem(
                      icon: Icons.star_rounded,
                      // Only earns the warning color once it's actually
                      // blocking the user from adding another member.
                      color: atMax ? AppColors.warning : AppColors.primary,
                      value: '${AppConfig.maxRelatives}',
                      label: 'จำนวนสูงสุด',
                    ),
                  ),
                  const _MemberStatDivider(),
                  Expanded(
                    child: _MemberStatItem(
                      icon: Icons.medical_information_rounded,
                      color: AppColors.primary,
                      value: '$withNotes',
                      label: 'มีโน้ตดูแล',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBox() {
    return AppTextField(
      controller: _searchController,
      hint: 'ค้นหาชื่อ, ความสัมพันธ์ หรือเบอร์โทร',
      prefixIcon: Icons.search,
      onChanged: (_) => setState(() {}),
      suffixIcon: _searchController.text.isEmpty
          ? null
          : IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              icon: const Icon(Icons.close),
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

  Future<void> _setDefault(CareMember member) async {
    await ref.read(memberRepositoryProvider).setDefault(member.id);
    await _load();
  }

  Future<void> _confirmDelete(CareMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบสมาชิก'),
        content: Text(
          'ต้องการลบ ${member.nickname} ออกจากรายชื่อผู้ดูแลใช่หรือไม่?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ลบ', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(memberRepositoryProvider).softDelete(member.id);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ยังไม่รองรับการลบสมาชิกในขณะนี้ กรุณาลองใหม่ภายหลัง'),
        ),
      );
    }
  }

  void _showMemberFormSheet({CareMember? member}) {
    final isEditing = member != null;
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController(
      text: member?.firstName ?? '',
    );
    final lastNameController = TextEditingController(
      text: member?.lastName ?? '',
    );
    final nicknameController = TextEditingController(
      text: member?.nickname ?? '',
    );
    final relationshipController = TextEditingController(
      text: member?.relationship ?? '',
    );
    final phoneController = TextEditingController(text: member?.phone ?? '');
    final ageController = TextEditingController(
      text: member == null || member.age == 0 ? '' : '${member.age}',
    );
    final careNoteController = TextEditingController(
      text: member?.careNote ?? '',
    );
    String gender = member != null && member.gender.isNotEmpty
        ? member.gender
        : _genderOptions.first.$1;
    String bloodType = member != null && member.bloodType.isNotEmpty
        ? member.bloodType
        : _bloodTypeOptions.first;
    var isSubmitting = false;

    final initialGender = gender;
    final initialBloodType = bloodType;
    bool hasUnsavedChanges() =>
        firstNameController.text != (member?.firstName ?? '') ||
        lastNameController.text != (member?.lastName ?? '') ||
        nicknameController.text != (member?.nickname ?? '') ||
        relationshipController.text != (member?.relationship ?? '') ||
        phoneController.text != (member?.phone ?? '') ||
        ageController.text !=
            (member == null || member.age == 0 ? '' : '${member.age}') ||
        careNoteController.text != (member?.careNote ?? '') ||
        gender != initialGender ||
        bloodType != initialBloodType;

    showModalBottomSheet(
      context: context,
      // See BankAccountRequiredSheet for why: the nearest (shell-nested)
      // Navigator sits under MainScaffold's floating bottom nav in paint
      // order, so this sheet would show with the nav pill poking through
      // on top of it instead of covering the whole screen.
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final textTheme = Theme.of(context).textTheme;

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return;
                if (!hasUnsavedChanges()) {
                  Navigator.of(context).pop();
                  return;
                }
                final leave = await confirmDiscardChanges(context);
                if (leave && context.mounted) Navigator.of(context).pop();
              },
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  24,
                  8,
                  24,
                  MediaQuery.of(context).viewInsets.bottom + 28,
                ),
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircleIconAvatar(
                          icon: isEditing
                              ? Icons.edit_rounded
                              : Icons.person_add_alt_1_rounded,
                          color: AppColors.primary,
                          radius: 32,
                          iconSize: 36,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          isEditing ? 'แก้ไขข้อมูลสมาชิก' : 'เพิ่มสมาชิกใหม่',
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 18),
                        AppTextField(
                          controller: firstNameController,
                          label: 'ชื่อจริง',
                          hint: 'เช่น สมชาย',
                          prefixIcon: Icons.badge_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'กรุณากรอกชื่อจริง'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: lastNameController,
                          label: 'นามสกุล',
                          hint: 'เช่น ใจดี',
                          prefixIcon: Icons.badge_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'กรุณากรอกนามสกุล'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: nicknameController,
                          label: 'ชื่อเล่น',
                          prefixIcon: Icons.face_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'กรุณากรอกชื่อเล่น'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: relationshipController,
                          label: 'ความสัมพันธ์',
                          hint: 'เช่น บิดา, มารดา, ญาติ',
                          prefixIcon: Icons.diversity_3_outlined,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'กรุณากรอกความสัมพันธ์'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: phoneController,
                          label: 'เบอร์โทรศัพท์',
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (v) =>
                              (v == null || !RegExp(r'^0[0-9]{9}$').hasMatch(v))
                              ? 'เบอร์โทรไม่ถูกต้อง'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: ageController,
                          label: 'อายุ',
                          keyboardType: TextInputType.number,
                          prefixIcon: Icons.cake_outlined,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'กรุณากรอกอายุ';
                            }
                            final age = int.tryParse(v.trim());
                            if (age == null || age < 0 || age > 120) {
                              return 'กรุณากรอกอายุระหว่าง 0-120 ปี';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: gender,
                                decoration: const InputDecoration(
                                  labelText: 'เพศ',
                                ),
                                items: _genderOptions
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g.$1,
                                        child: Text(g.$2),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setSheetState(() => gender = v ?? gender),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: bloodType,
                                decoration: const InputDecoration(
                                  labelText: 'กรุ๊ปเลือด',
                                ),
                                items: _bloodTypeOptions
                                    .map(
                                      (b) => DropdownMenuItem(
                                        value: b,
                                        child: Text(b),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) => setSheetState(
                                  () => bloodType = v ?? bloodType,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: careNoteController,
                          label: 'หมายเหตุการดูแล',
                          maxLines: 3,
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: isSubmitting
                              ? 'กำลังบันทึก...'
                              : (isEditing ? 'บันทึกการแก้ไข' : 'เพิ่มสมาชิก'),
                          icon: isEditing ? Icons.save_rounded : Icons.add,
                          isLoading: isSubmitting,
                          onPressed: isSubmitting
                              ? null
                              : () async {
                                  final isValid =
                                      formKey.currentState?.validate() ?? false;
                                  if (!isValid) return;

                                  setSheetState(() => isSubmitting = true);
                                  try {
                                    final repo = ref.read(
                                      memberRepositoryProvider,
                                    );
                                    if (isEditing) {
                                      await repo.update(
                                        id: member.id,
                                        firstName: firstNameController.text
                                            .trim(),
                                        lastName: lastNameController.text
                                            .trim(),
                                        nickname: nicknameController.text
                                            .trim(),
                                        relationship: relationshipController
                                            .text
                                            .trim(),
                                        phone: phoneController.text.trim(),
                                        age:
                                            int.tryParse(
                                              ageController.text.trim(),
                                            ) ??
                                            0,
                                        gender: gender,
                                        bloodType: bloodType,
                                        careNote: careNoteController.text
                                            .trim(),
                                      );
                                    } else {
                                      await repo.create(
                                        firstName: firstNameController.text
                                            .trim(),
                                        lastName: lastNameController.text
                                            .trim(),
                                        nickname: nicknameController.text
                                            .trim(),
                                        relationship: relationshipController
                                            .text
                                            .trim(),
                                        phone: phoneController.text.trim(),
                                        age:
                                            int.tryParse(
                                              ageController.text.trim(),
                                            ) ??
                                            0,
                                        gender: gender,
                                        bloodType: bloodType,
                                        careNote: careNoteController.text
                                            .trim(),
                                      );
                                    }
                                    if (context.mounted) Navigator.pop(context);
                                    await _load();
                                  } on MaxRelativesReachedException catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(content: Text(e.toString())),
                                      );
                                    }
                                  } on ApiException catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            friendlyErrorMessage(e),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            friendlyErrorMessage(e),
                                          ),
                                        ),
                                      );
                                    }
                                  } finally {
                                    if (context.mounted) {
                                      setSheetState(() => isSubmitting = false);
                                    }
                                  }
                                },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showMemberDetail(CareMember member) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleIconAvatar(
                icon: member.icon,
                color: member.color,
                radius: 42,
                filled: true,
                iconSize: 42,
              ),
              const SizedBox(height: 14),
              Text(
                member.fullName,
                textAlign: TextAlign.center,
                style: textTheme.headlineSmall,
              ),
              const SizedBox(height: 6),
              Text(
                '${member.relationship} • ${member.age} ปี • กรุ๊ปเลือด ${member.bloodType}',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
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
                value: _genderLabel(member.gender),
              ),
              _DetailRow(
                icon: Icons.note_alt_outlined,
                label: 'หมายเหตุการดูแล',
                value: member.careNote.isEmpty ? '-' : member.careNote,
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showMemberFormSheet(member: member);
                  },
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('แก้ไขข้อมูล'),
                ),
              ),
              if (!member.isSelf) ...[
                const SizedBox(height: 14),
                PrimaryButton(
                  label: member.isDefault
                      ? 'เป็นค่าเริ่มต้นอยู่แล้ว'
                      : 'ตั้งเป็นค่าเริ่มต้น',
                  icon: Icons.star_rounded,
                  onPressed: member.isDefault
                      ? null
                      : () {
                          Navigator.pop(context);
                          _setDefault(member);
                        },
                ),
              ],
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
    this.onSetDefault,
    this.onDelete,
  });

  final CareMember member;
  final VoidCallback onTap;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Hero(
                tag: 'member-${member.id}',
                child: CircleIconAvatar(
                  icon: member.icon,
                  color: member.color,
                  radius: 30,
                  iconSize: 32,
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
                            style: textTheme.titleMedium,
                          ),
                        ),
                        if (member.isDefault) ...[
                          const SizedBox(width: 8),
                          const StatusBadge(
                            text: 'Default',
                            color: AppColors.badgeDefault,
                            icon: Icons.star_rounded,
                            dense: true,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${member.relationship} • ${member.age} ปี • ${member.phone}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.danger,
                  ),
                ),
            ],
          ),
          if (member.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: member.tags
                    .map(
                      (tag) => StatusBadge(
                        text: tag,
                        color: member.color,
                        dense: true,
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
          if (member.careNote.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
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
                      style: textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (onSetDefault != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onSetDefault,
                icon: const Icon(Icons.star_outline_rounded),
                label: const Text('ตั้งเป็นค่าเริ่มต้น'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MemberStatDivider extends StatelessWidget {
  const _MemberStatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.divider);
  }
}

class _MemberStatItem extends StatelessWidget {
  const _MemberStatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        CircleIconAvatar(icon: icon, color: color, radius: 18, iconSize: 18),
        const SizedBox(height: 8),
        Text(value, style: textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(label, style: textTheme.labelMedium),
      ],
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
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: textTheme.labelMedium),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
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
