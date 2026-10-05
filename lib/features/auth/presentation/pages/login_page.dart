// Aurora Glass auth — full-screen aurora blobs behind a single frosted-glass
// hero card. See DESIGN.md ("Aurora & Glass").

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../controllers/auth_controller.dart';
import '../widgets/otp_verification_sheet.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _error = null);

    final phone = _phoneController.text.trim();
    final auth = ref.read(authControllerProvider);

    try {
      await auth.requestLoginOtp(phone);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(
        () => _error = e.statusCode == 404
            ? 'ไม่พบบัญชีที่ใช้เบอร์โทรนี้ กรุณาสมัครสมาชิกก่อน'
            : e.message,
      );
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'ส่งรหัส OTP ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
      return;
    }
    if (!mounted) return;

    await OtpVerificationSheet.show(
      context,
      phone: phone,
      onVerify: (code) => auth.login(phone, code),
      onResend: () => auth.requestLoginOtp(phone),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: AuroraBackground(height: screenHeight)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: AppCard(
                  glass: true,
                  padding: const EdgeInsets.all(28),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: Image.asset(
                            'assets/images/app_icon.png',
                            width: 88,
                            height: 88,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'ยินดีต้อนรับสู่ CareMate',
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
                        const SizedBox(height: 32),
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
                        const SizedBox(height: 24),
                        PrimaryButton(
                          label: auth.isSubmitting
                              ? 'กำลังเข้าสู่ระบบ...'
                              : 'เข้าสู่ระบบ',
                          icon: Icons.login_rounded,
                          isLoading: auth.isSubmitting,
                          onPressed: auth.isSubmitting ? null : _login,
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: auth.isSubmitting
                              ? null
                              : () => context.goForward(AppRoutes.register),
                          child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
