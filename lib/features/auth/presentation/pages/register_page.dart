// Aurora Glass auth — aurora blobs behind the hero intro card; the long
// form card stays solid white for legibility. See DESIGN.md ("Aurora & Glass").

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/storage/local_storage.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_verification_sheet.dart';
import '../widgets/pdpa_consent_dialog.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

// Must match the only gender values the backend actually accepts —
// `UpdateUserPersonalInformationRequest.Validate()` in care-mate-backend
// (internal/dto/user_dto.go) rejects anything outside male/female/unspecified
// with ErrGenderInvalid. Register's own DTO doesn't validate gender at all,
// but sending a value the *update* endpoint will later reject (e.g. the old
// "other") breaks editing personal info for that user forever after.
const _genderOptions = [
  ('male', 'ชาย'),
  ('female', 'หญิง'),
  ('unspecified', 'ไม่ระบุ'),
];

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _referralCodeController = TextEditingController();
  String _gender = _genderOptions.first.$1;
  DateTime? _dateOfBirth;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _referralCodeController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
    );

    if (picked == null) return;
    setState(() => _dateOfBirth = picked);
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_dateOfBirth == null) {
      setState(() => _error = 'กรุณาเลือกวันเกิด');
      return;
    }

    setState(() => _error = null);

    final phone = _phoneController.text.trim();
    final verified = await OtpVerificationSheet.show(context, phone: phone);
    if (!verified) return;
    if (!mounted) return;

    final pdpaConsentVersion = await PdpaConsentDialog.show(context);
    if (pdpaConsentVersion == null) return;
    await ref
        .read(localStorageProvider)
        .savePdpaConsentGiven(pdpaConsentVersion);
    if (!mounted) return;

    final dateOfBirthIso = _dateOfBirth!.toIso8601String().split('T').first;

    try {
      await ref
          .read(authControllerProvider)
          .register(
            phone: phone,
            firstName: _firstNameController.text.trim(),
            lastName: _lastNameController.text.trim(),
            nickname: _nicknameController.text.trim(),
            gender: _gender,
            dateOfBirth: dateOfBirthIso,
            email: _emailController.text.trim(),
            pdpaConsentVersion: pdpaConsentVersion,
            referralCode: _referralCodeController.text.trim().isEmpty
                ? null
                : _referralCodeController.text.trim(),
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'สมัครสมาชิกไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
        leading: BackButton(onPressed: () => context.goBack(AppRoutes.login)),
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
                        icon: Icons.person_add_alt_1,
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
                              'สร้างบัญชีใหม่',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'กรอกข้อมูลเบื้องต้น รายละเอียดอื่นแก้ไขเพิ่มเติมได้ภายหลัง',
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
                        controller: _nicknameController,
                        label: 'ชื่อเล่น',
                        prefixIcon: Icons.face_outlined,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'กรุณากรอกชื่อเล่น'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _gender,
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
                                  setState(() => _gender = v ?? _gender),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _pickDateOfBirth,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'วันเกิด',
                                ),
                                child: Text(
                                  _dateOfBirth == null
                                      ? 'เลือกวันเกิด'
                                      : _formatDate(_dateOfBirth!),
                                  style: TextStyle(
                                    color: _dateOfBirth == null
                                        ? AppColors.textSecondary
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _emailController,
                        label: 'อีเมล',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty)
                            return 'กรุณากรอกอีเมล';
                          if (!RegExp(
                            r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                          ).hasMatch(v.trim()))
                            return 'อีเมลไม่ถูกต้อง';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _referralCodeController,
                        label: 'รหัสชวนเพื่อน (ถ้ามี)',
                        hint: 'กรอกรหัสจากเพื่อนที่ชวนคุณมา',
                        prefixIcon: Icons.card_giftcard_outlined,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: auth.isSubmitting
                      ? 'กำลังสมัครสมาชิก...'
                      : 'สมัครสมาชิก',
                  icon: Icons.person_add_rounded,
                  isLoading: auth.isSubmitting,
                  onPressed: auth.isSubmitting ? null : _register,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
