import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/profile_repository.dart';

class PersonalInformationPage extends ConsumerStatefulWidget {
  const PersonalInformationPage({super.key});

  @override
  ConsumerState<PersonalInformationPage> createState() =>
      _PersonalInformationPageState();
}

class _PersonalInformationPageState
    extends ConsumerState<PersonalInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  UserProfile? _profile;
  DateTime? _dateOfBirth;
  String _gender = '';

  static const _genderOptions = [
    ('male', 'ชาย'),
    ('female', 'หญิง'),
    ('unspecified', 'ไม่ระบุ'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    final profile = await ref.read(profileRepositoryProvider).getForUser(user);
    if (!mounted) return;

    setState(() {
      _profile = profile;
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _phoneController.text = user.phone;
      _emailController.text = profile.email;
      _dateOfBirth = profile.dateOfBirth;
      _gender = profile.gender;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 30),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );
    if (picked == null) return;
    setState(() => _dateOfBirth = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profile = _profile;
    if (profile == null) return;

    setState(() => _isSaving = true);

    final updated = profile.copyWith(
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
      dateOfBirth: _dateOfBirth,
      gender: _gender,
    );

    await ref.read(profileRepositoryProvider).update(updated);
    await ref.read(authControllerProvider).refreshUser();

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกข้อมูลส่วนตัวเรียบร้อยแล้ว')),
    );
    context.go(AppRoutes.profile);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ข้อมูลส่วนตัว'),
          leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ข้อมูลส่วนตัว'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Stack(
        children: [
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuroraBackground(height: 320),
          ),
          Form(
            key: _formKey,
            child: ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                MediaQuery.paddingOf(context).top + 68,
                20,
                32,
              ),
              children: [
                AppCard(
                  glass: true,
                  child: Row(
                    children: [
                      const CircleIconAvatar(
                        icon: Icons.person,
                        color: AppColors.primary,
                        radius: 28,
                        filled: true,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'แก้ไขข้อมูลพื้นฐาน',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'ข้อมูลนี้ใช้สำหรับการติดต่อและระบุตัวตนของคุณ',
                              style: textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _firstNameController,
                              label: 'ชื่อจริง',
                              prefixIcon: Icons.badge_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'กรุณากรอกชื่อจริง'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppTextField(
                              controller: _lastNameController,
                              label: 'นามสกุล',
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'กรุณากรอกนามสกุล'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _phoneController,
                        label: 'เบอร์โทรศัพท์',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) =>
                            (v == null || !RegExp(r'^0[0-9]{9}$').hasMatch(v))
                            ? 'เบอร์โทรไม่ถูกต้อง'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _emailController,
                        label: 'อีเมล',
                        hint: 'example@email.com',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: _pickDateOfBirth,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'วันเกิด',
                            prefixIcon: Icon(Icons.cake_outlined),
                          ),
                          child: Text(
                            _dateOfBirth == null
                                ? 'เลือกวันเกิด'
                                : _formatDate(_dateOfBirth!),
                            style: textTheme.bodyLarge,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: _gender.isEmpty ? null : _gender,
                        decoration: const InputDecoration(
                          labelText: 'เพศ',
                          prefixIcon: Icon(Icons.wc_outlined),
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
                            setState(() => _gender = v ?? _gender),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: _isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล',
                  icon: Icons.save_rounded,
                  isLoading: _isSaving,
                  onPressed: _isSaving ? null : _save,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
