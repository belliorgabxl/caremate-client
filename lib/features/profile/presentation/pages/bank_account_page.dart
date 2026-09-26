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
import '../../../../shared/widgets/back_circle_button.dart';
import '../../../../shared/widgets/bank_logo_avatar.dart';
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
  ThaiBank? _bank;

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
        _bank = account.bankName.isEmpty
            ? null
            : thaiBanks.cast<ThaiBank?>().firstWhere(
                (b) => b!.name == account.bankName,
                orElse: () => null,
              );
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
            bankName: _bank!.name,
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

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกบัญชีธนาคารเรียบร้อยแล้ว')),
    );
    context.popBack(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _loadError != null) {
      return Scaffold(
        body: Stack(
          children: [
            SafeArea(
              child: _isLoading
                  ? const SizedBox.shrink()
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
            ),
            Positioned(
              top: MediaQuery.paddingOf(context).top + 8,
              left: 20,
              child: BackCircleButton(
                onTap: () => context.popBack(AppRoutes.profile),
              ),
            ),
          ],
        ),
      );
    }

    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
                  title: 'บัญชีธนาคารของผู้ใช้',
                  subtitle:
                      'จำเป็นสำหรับการคืนเงินในกรณีที่ระบบไม่สามารถคืนเงินอัตโนมัติได้',
                  icon: Icons.account_balance_outlined,
                ),
                const SizedBox(height: 12),
                AppCard(
                  child: Column(
                    children: [
                      DropdownButtonFormField<ThaiBank>(
                        initialValue: _bank,
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'ธนาคาร'),
                        items: thaiBanks
                            .map(
                              (b) => DropdownMenuItem(
                                value: b,
                                child: Row(
                                  children: [
                                    BankLogoAvatar(bank: b, radius: 13),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        b.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                        selectedItemBuilder: (context) => thaiBanks
                            .map(
                              (b) => Row(
                                children: [
                                  BankLogoAvatar(bank: b, radius: 13),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      b.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _bank = v),
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
          // Painted after the Form/ListView so it stays on top for
          // hit-testing — listed before it, the ListView's own (invisible)
          // top padding sat above it in the Stack and swallowed the tap,
          // making this back button silently do nothing.
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 20,
            child: BackCircleButton(
              onTap: () => context.popBack(AppRoutes.profile),
            ),
          ),
        ],
      ),
    );
  }
}
