import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';

/// Client-side **mock** OTP gate — the backend has no SMS/OTP endpoint for
/// customer login/register (only a separate partner-app OTP system exists,
/// for a different actor). This exists purely so the product flow *behaves*
/// like phone ownership is verified while that's built; the generated code
/// is shown on-screen (never actually sent anywhere), and is clearly labeled
/// as a placeholder so nobody mistakes it for real security. Replace with a
/// real `POST /authentication/otp/*` integration once the backend adds one.
class OtpVerificationSheet {
  static Future<bool> show(BuildContext context, {required String phone}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _OtpSheetBody(phone: phone),
    );
    return result ?? false;
  }
}

class _OtpSheetBody extends StatefulWidget {
  const _OtpSheetBody({required this.phone});

  final String phone;

  @override
  State<_OtpSheetBody> createState() => _OtpSheetBodyState();
}

class _OtpSheetBodyState extends State<_OtpSheetBody> {
  final _codeController = TextEditingController();
  late String _sentCode;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sentCode = _generateCode();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  String _generateCode() => (100000 + Random().nextInt(900000)).toString();

  void _resend() {
    setState(() {
      _sentCode = _generateCode();
      _codeController.clear();
      _error = null;
    });
  }

  void _verify() {
    if (_codeController.text.trim() == _sentCode) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _error = 'รหัส OTP ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง');
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('ยืนยันเบอร์โทรศัพท์', style: textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'กรอกรหัส OTP ที่ส่งไปยัง ${widget.phone}',
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.science_outlined,
                  color: AppColors.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'รหัสของคุณคือ $_sentCode',
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppTextField(
            controller: _codeController,
            label: 'รหัส OTP 6 หลัก',
            prefixIcon: Icons.password_outlined,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(label: 'ยืนยัน', onPressed: _verify),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(onPressed: _resend, child: const Text('ส่งรหัสอีกครั้ง')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('ยกเลิก'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
