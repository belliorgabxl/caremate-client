import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/thai_banks.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../data/profile_repository.dart';

/// Lets a customer view/edit the bank account saved as a manual-refund
/// fallback (see [ProfileRepository.saveBankAccount]) after the initial
/// booking-gate entry — that gate only ever creates the account once and
/// has no way back into it.
class BankAccountPage extends ConsumerStatefulWidget {
  const BankAccountPage({super.key});

  @override
  ConsumerState<BankAccountPage> createState() => _BankAccountPageState();
}

class _BankAccountPageState extends ConsumerState<BankAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _bankAccountController = TextEditingController();
  final _bankAccountNameController = TextEditingController();
  String? _bankName;

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bankAccountController.dispose();
    _bankAccountNameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final account = await ref
          .read(profileRepositoryProvider)
          .getBankAccount();
      if (!mounted) return;
      setState(() {
        _bankName = account.bankName.isEmpty ? null : account.bankName;
        _bankAccountController.text = account.bankAccount;
        _bankAccountNameController.text = account.bankAccountName;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = friendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      await ref
          .read(profileRepositoryProvider)
          .saveBankAccount(
            bankName: _bankName!,
            bankAccount: _bankAccountController.text.trim(),
            bankAccountName: _bankAccountNameController.text.trim(),
          );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = friendlyErrorMessage(e);
      });
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกบัญชีธนาคารเรียบร้อยแล้ว')));
    context.goBack(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('บัญชีธนาคาร'),
          leading: BackButton(onPressed: () => context.goBack(AppRoutes.profile)),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
                children: [
                  EmptyState(
                    icon: Icons.error_outline_rounded,
                    title: 'โหลดข้อมูลไม่สำเร็จ',
                    message: _loadError!,
                    action: PrimaryButton(
                      label: 'ลองอีกครั้ง',
                      icon: Icons.refresh_rounded,
                      expanded: false,
                      onPressed: _load,
                    ),
                  ),
                ],
              ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('บัญชีธนาคาร'),
        leading: BackButton(onPressed: () => context.goBack(AppRoutes.profile)),
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
                const SectionHeader(
                  title: 'บัญชีธนาคารสำหรับคืนเงิน',
                  subtitle:
                      'จำเป็นสำหรับการคืนเงินในกรณีที่ระบบไม่สามารถคืนเงินอัตโนมัติได้',
                  icon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: _bankName,
                        decoration: const InputDecoration(
                          labelText: 'ธนาคาร',
                          prefixIcon: Icon(Icons.account_balance_outlined),
                        ),
                        items: thaiBanks
                            .map(
                              (b) => DropdownMenuItem(value: b, child: Text(b)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _bankName = v),
                        validator: (v) => v == null ? 'กรุณาเลือกธนาคาร' : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _bankAccountController,
                        label: 'เลขบัญชี',
                        prefixIcon: Icons.numbers_outlined,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'กรุณากรอกเลขบัญชี'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      AppTextField(
                        controller: _bankAccountNameController,
                        label: 'ชื่อบัญชี',
                        prefixIcon: Icons.person_outline,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? 'กรุณากรอกชื่อบัญชี'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'ข้อมูลบัญชีนี้ใช้สำหรับการคืนเงินกรณียกเลิกธุรกรรมเท่านั้น '
                          'หากชื่อบัญชีไม่ตรงกับธนาคารเจ้าของบัญชี ระบบจะไม่สามารถคืนเงินให้ได้',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_saveError != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _saveError!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'บันทึกบัญชีธนาคาร',
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
