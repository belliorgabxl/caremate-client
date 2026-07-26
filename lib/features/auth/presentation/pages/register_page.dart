import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/auth_exception.dart';
import '../controllers/auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'กรุณากรอกชื่อ-นามสกุล';
    return null;
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    FocusScope.of(context).unfocus();
    final auth = ref.read(authControllerProvider);

    try {
      await auth.register(displayName: _nameController.text.trim());
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final textTheme = Theme.of(context).textTheme;

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
                  icon: Icons.person_add_alt_1_rounded,
                  color: AppColors.primary,
                  radius: 46,
                  iconSize: 46,
                ),
                const SizedBox(height: 24),
                Text('ยินดีต้อนรับสู่ CareMate', textAlign: TextAlign.center, style: textTheme.headlineLarge),
                const SizedBox(height: 8),
                Text(
                  'เบอร์ ${auth.pendingPhone ?? '-'} ยังไม่เคยลงทะเบียน\nกรอกชื่อของคุณเพื่อสร้างบัญชีใหม่',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 32),
                AppTextField(
                  controller: _nameController,
                  label: 'ชื่อ-นามสกุล',
                  hint: 'เช่น สมชาย ใจดี',
                  prefixIcon: Icons.badge_outlined,
                  validator: _validateName,
                  onFieldSubmitted: (_) => _submit(),
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: auth.isSubmitting ? 'กำลังสร้างบัญชี...' : 'สร้างบัญชีและเข้าสู่ระบบ',
                  icon: Icons.check_circle_rounded,
                  isLoading: auth.isSubmitting,
                  onPressed: auth.isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
