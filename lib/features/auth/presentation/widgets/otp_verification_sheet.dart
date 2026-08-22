import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';


class OtpVerificationSheet {
  static Future<String?> show(
    BuildContext context, {
    required String phone,
    Future<void> Function(String code)? onVerify,
    required Future<void> Function() onResend,
  }) async {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _OtpSheetBody(
        phone: phone,
        onVerify: onVerify,
        onResend: onResend,
      ),
    );
  }
}

class _OtpSheetBody extends StatefulWidget {
  const _OtpSheetBody({
    required this.phone,
    required this.onVerify,
    required this.onResend,
  });

  final String phone;
  final Future<void> Function(String code)? onVerify;
  final Future<void> Function() onResend;

  @override
  State<_OtpSheetBody> createState() => _OtpSheetBodyState();
}

class _OtpSheetBodyState extends State<_OtpSheetBody> {
  final _codeController = TextEditingController();
  String? _error;
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _resend() async {
    setState(() {
      _isResending = true;
      _error = null;
    });
    try {
      await widget.onResend();
      if (!mounted) return;
      setState(() => _codeController.clear());
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'ส่งรหัส OTP ไม่สำเร็จ กรุณาลองใหม่อีกครั้ง');
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'กรุณากรอกรหัส OTP ให้ครบ 6 หลัก');
      return;
    }

    final onVerify = widget.onVerify;
    if (onVerify == null) {
      Navigator.of(context).pop(code);
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });
    try {
      await onVerify(code);
      if (!mounted) return;
      Navigator.of(context).pop(code);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'รหัส OTP ไม่ถูกต้อง กรุณาลองใหม่อีกครั้ง');
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final isBusy = _isVerifying || _isResending;

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
          PrimaryButton(
            label: 'ยืนยัน',
            isLoading: _isVerifying,
            onPressed: isBusy ? null : _verify,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: isBusy ? null : _resend,
                child: Text(_isResending ? 'กำลังส่ง...' : 'ส่งรหัสอีกครั้ง'),
              ),
              TextButton(
                onPressed: isBusy ? null : () => Navigator.of(context).pop(),
                child: const Text('ยกเลิก'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
