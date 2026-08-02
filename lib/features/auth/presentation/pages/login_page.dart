import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/app_text_field.dart';
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
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _error = null);

    try {
      await ref.read(authControllerProvider).login(_phoneController.text.trim());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'เข้าสู่ระบบไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _phoneController,
                  label: 'เบอร์โทรศัพท์',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) => (v == null || !RegExp(r'^0[0-9]{9}$').hasMatch(v)) ? 'เบอร์โทรไม่ถูกต้อง' : null,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: auth.isSubmitting ? 'กำลังเข้าสู่ระบบ...' : 'เข้าสู่ระบบ',
                  icon: Icons.login_rounded,
                  isLoading: auth.isSubmitting,
                  onPressed: auth.isSubmitting ? null : _login,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: auth.isSubmitting ? null : () => context.go(AppRoutes.register),
                  child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
