import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../data/profile_repository.dart';

/// Blocks entry into the booking wizard until the customer has a bank
/// account on file — needed as a manual refund fallback when Beam can't
/// refund the original charge automatically. Not dismissible by swipe/tap;
/// the only way out is saving successfully or the explicit "ยกเลิก" button,
/// which the caller treats as "don't proceed to booking."
class BankAccountRequiredSheet {
  static Future<bool> show(
    BuildContext context, {
    required ProfileRepository repository,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => _BankAccountSheetBody(repository: repository),
    );
    return saved ?? false;
  }
}

class _BankAccountSheetBody extends StatefulWidget {
  const _BankAccountSheetBody({required this.repository});

  final ProfileRepository repository;

  @override
  State<_BankAccountSheetBody> createState() => _BankAccountSheetBodyState();
}

class _BankAccountSheetBodyState extends State<_BankAccountSheetBody> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  String? _error;
  bool _isSaving = false;

  @override
  void dispose() {
    _bankNameController.dispose();
    _bankAccountController.dispose();
    _bankAccountNameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });
    try {
      await widget.repository.saveBankAccount(
        bankName: _bankNameController.text.trim(),
        bankAccount: _bankAccountController.text.trim(),
        bankAccountName: _bankAccountNameController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'บันทึกบัญชีธนาคารไม่สำเร็จ กรุณาลองใหม่อีกครั้ง',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
      child: Form(
        key: _formKey,
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
            Text('เพิ่มบัญชีธนาคาร', style: textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'จำเป็นสำหรับการคืนเงินในกรณีที่ระบบไม่สามารถคืนเงินอัตโนมัติได้ '
              'กรุณากรอกก่อนทำการจองครั้งแรก',
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            AppTextField(
              controller: _bankNameController,
              label: 'ธนาคาร',
              prefixIcon: Icons.account_balance_outlined,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'กรุณากรอกชื่อธนาคาร'
                  : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _bankAccountController,
              label: 'เลขบัญชี',
              prefixIcon: Icons.numbers_outlined,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'กรุณากรอกเลขบัญชี' : null,
            ),
            const SizedBox(height: 12),
            AppTextField(
              controller: _bankAccountNameController,
              label: 'ชื่อบัญชี',
              prefixIcon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'กรุณากรอกชื่อบัญชี' : null,
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
              label: 'บันทึกและดำเนินการต่อ',
              isLoading: _isSaving,
              onPressed: _isSaving ? null : _save,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isSaving
                  ? null
                  : () => Navigator.of(context).pop(false),
              child: const Text('ยกเลิก'),
            ),
          ],
        ),
      ),
    );
  }
}
