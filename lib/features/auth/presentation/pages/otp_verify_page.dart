import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/auth_exception.dart';
import '../controllers/auth_controller.dart';

class OtpVerifyPage extends ConsumerStatefulWidget {
  const OtpVerifyPage({super.key});

  @override
  ConsumerState<OtpVerifyPage> createState() => _OtpVerifyPageState();
}

class _OtpVerifyPageState extends ConsumerState<OtpVerifyPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  Timer? _cooldownTimer;
  int _cooldownSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startCooldown();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = AppConfig.otpResendCooldown.inSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds -= 1);
      }
    });
  }

  String? _validateCode(String? value) {
    final code = value?.trim() ?? '';
    if (code.length != AppConfig.otpLength) {
      return 'กรุณากรอกรหัส OTP ${AppConfig.otpLength} หลัก';
    }
    return null;
  }

  Future<void> _verify() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    final auth = ref.read(authControllerProvider);

    try {
      await auth.verifyOtp(_codeController.text.trim());
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  Future<void> _resend() async {
    final auth = ref.read(authControllerProvider);
    final phone = auth.pendingPhone;
    if (phone == null) return;

    await auth.requestOtp(phone);
    _startCooldown();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final phone = auth.pendingPhone ?? '';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: auth.backToPhoneEntry,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const CircleIconAvatar(
                  icon: Icons.sms_rounded,
                  color: AppColors.primary,
                  radius: 46,
                  iconSize: 46,
                ),
                const SizedBox(height: 24),
                Text('ยืนยันรหัส OTP', textAlign: TextAlign.center, style: textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'กรอกรหัส OTP ที่ส่งไปยังเบอร์ $phone',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _codeController,
                  label: 'รหัส OTP',
                  hint: 'กรอกรหัส ${AppConfig.otpLength} หลัก',
                  keyboardType: TextInputType.number,
                  maxLength: AppConfig.otpLength,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: _validateCode,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onFieldSubmitted: (_) => _verify(),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: auth.isSubmitting ? 'กำลังตรวจสอบ...' : 'ยืนยัน OTP',
                  icon: Icons.check_circle_rounded,
                  isLoading: auth.isSubmitting,
                  onPressed: auth.isSubmitting ? null : _verify,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _cooldownSeconds > 0 ? null : _resend,
                    child: Text(
                      _cooldownSeconds > 0 ? 'ส่งรหัสอีกครั้งใน $_cooldownSeconds วินาที' : 'ส่งรหัส OTP อีกครั้ง',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
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
                          'โหมดจำลอง: รหัส OTP ของคุณคือ ${auth.lastOtpForDemo ?? '-'}',
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
    );
  }
}
