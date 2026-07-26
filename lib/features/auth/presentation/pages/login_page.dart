import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'กรุณากรอกเบอร์โทรศัพท์';
    }

    if (!RegExp(r'^0[0-9]{9}$').hasMatch(phone)) {
      return 'เบอร์โทรศัพท์ต้องขึ้นต้นด้วย 0 และมี 10 หลัก';
    }

    return null;
  }

  Future<void> _submitLogin() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();

    final phone = _phoneController.text.trim();
    await ref.read(authControllerProvider).requestOtp(phone);
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  48,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 64),
                  const CircleIconAvatar(
                    icon: Icons.health_and_safety,
                    color: AppColors.primary,
                    radius: 46,
                    iconSize: 52,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to CareMate',
                    textAlign: TextAlign.center,
                    style: textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'เข้าสู่ระบบด้วยเบอร์โทรศัพท์เพื่อเริ่มจองบริการดูแลสุขภาพ',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 40),

                  AppTextField(
                    controller: _phoneController,
                    label: 'เบอร์โทรศัพท์',
                    hint: 'เช่น 09X-XXX-XXXX',
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    prefixIcon: Icons.phone_outlined,
                    validator: _validatePhone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onFieldSubmitted: (_) => _submitLogin(),
                  ),

                  const SizedBox(height: 20),

                  PrimaryButton(
                    label: auth.isSubmitting ? 'กำลังส่งรหัส OTP...' : 'ขอรหัส OTP',
                    icon: Icons.sms_rounded,
                    isLoading: auth.isSubmitting,
                    onPressed: auth.isSubmitting ? null : _submitLogin,
                  ),

                  const SizedBox(height: 12),
                  Text(
                    'กรุณากรอกเบอร์โทรศัพท์ของคุณ',
                    style: textTheme.labelMedium,
                  ),

                  const SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'โหมดจำลอง: ยังไม่เชื่อมต่อผู้ให้บริการ SMS จริง ระบบจะแสดงรหัส OTP ให้ในหน้าถัดไป\n'
                            'ทดลองใช้เบอร์ ${AppConfig.demoExistingPhone} เพื่อเข้าสู่ระบบบัญชีตัวอย่าง หรือเบอร์อื่นเพื่อสมัครสมาชิกใหม่',
                            style: textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
