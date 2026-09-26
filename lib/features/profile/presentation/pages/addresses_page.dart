import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/address.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/utils/confirm_dialogs.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/back_circle_button.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/location_picker_page.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/profile_repository.dart';

class AddressesPage extends ConsumerStatefulWidget {
  const AddressesPage({super.key});

  @override
  ConsumerState<AddressesPage> createState() => _AddressesPageState();
}

class _AddressesPageState extends ConsumerState<AddressesPage> {
  final _addressController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  UserProfile? _profile;
  Address? _pickedLocation;
  String? _error;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) return;

    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final profile = await ref
          .read(profileRepositoryProvider)
          .getForUser(user);
      if (!mounted) return;

      setState(() {
        _profile = profile;
        _pickedLocation = profile.address;
        _addressController.text = profile.address?.addressLine ?? '';
        _isLoading = false;
        _dirty = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = friendlyErrorMessage(e);
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<bool> _confirmLeave() async {
    if (!_dirty) return true;
    return confirmDiscardChanges(context);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _handleBack() async {
    if (await _confirmLeave()) {
      if (!mounted) return;
      context.popBack(AppRoutes.profile);
    }
  }

  Future<void> _pickOnMap() async {
    final picked = await Navigator.of(context).push<Address>(
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          title: 'เลือกที่อยู่บนแผนที่',
          initialAddress: _pickedLocation,
        ),
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _pickedLocation = picked;
      _addressController.text = picked.addressLine;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    final profile = _profile;
    if (profile == null) return;

    if (_addressController.text.trim().isEmpty) {
      setState(() => _error = 'กรุณากรอกที่อยู่');
      return;
    }
    if (_pickedLocation?.hasCoordinates != true) {
      setState(() => _error = 'กรุณาเลือกตำแหน่งบนแผนที่');
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    final updated = profile.copyWith(
      address: Address(
        addressLine: _addressController.text.trim(),
        latitude: _pickedLocation!.latitude,
        longitude: _pickedLocation!.longitude,
      ),
    );

    try {
      await ref.read(profileRepositoryProvider).update(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _error = friendlyErrorMessage(e);
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _dirty = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('บันทึกที่อยู่เรียบร้อยแล้ว')));
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
          ListView(
            padding: EdgeInsets.fromLTRB(
              20,
              MediaQuery.paddingOf(context).top + 68,
              20,
              32,
            ),
            children: [
              const SectionHeader(
                title: 'ที่อยู่หลัก',
                subtitle: 'ใช้เป็นค่าเริ่มต้นเมื่อจองบริการ',
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _addressController,
                      label: 'รายละเอียดที่อยู่',
                      hint: 'บ้านเลขที่ ถนน แขวง/ตำบล เขต/อำเภอ',
                      prefixIcon: Icons.home_outlined,
                      maxLines: 3,
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      onTap: _pickOnMap,
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.map_rounded,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'เลือกตำแหน่งบนแผนที่',
                                    style: textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _pickedLocation?.hasCoordinates == true
                                        ? 'ตำแหน่งที่ปักหมุด (ไม่พบชื่อสถานที่)'
                                        : 'ยังไม่ได้ปักหมุด',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.dangerBg,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    _error!,
                    style: textTheme.bodySmall?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Text(
                  'ที่อยู่นี้จะถูกใช้เป็นจุดรับเริ่มต้นเมื่อคุณสร้างการจองใหม่',
                  style: textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isSaving ? 'กำลังบันทึก...' : 'บันทึกที่อยู่',
                icon: Icons.save_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
          // Painted after the ListView so it stays on top for hit-testing.
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 20,
            child: BackCircleButton(onTap: _handleBack),
          ),
        ],
      ),
    );
  }
}
