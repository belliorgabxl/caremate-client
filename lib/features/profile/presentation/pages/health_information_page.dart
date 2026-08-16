import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/error_messages.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/utils/confirm_dialogs.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/profile_repository.dart';

class HealthInformationPage extends ConsumerStatefulWidget {
  const HealthInformationPage({super.key});

  @override
  ConsumerState<HealthInformationPage> createState() =>
      _HealthInformationPageState();
}

class _HealthInformationPageState extends ConsumerState<HealthInformationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _diseasesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _careNoteController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String? _saveError;
  bool _dirty = false;
  UserProfile? _profile;
  String _bloodType = '';
  String _emergencyRelationship = '';

  static const _bloodTypes = ['A', 'B', 'AB', 'O'];
  static const _relationships = [
    'คู่สมรส',
    'บิดา',
    'มารดา',
    'บุตร',
    'ญาติ',
    'เพื่อน',
    'อื่นๆ',
  ];

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
        _emergencyNameController.text = profile.emergencyContactName;
        _emergencyPhoneController.text = profile.emergencyContactPhone;
        _emergencyRelationship = profile.emergencyContactRelationship;
        _bloodType = profile.bloodType;
        _allergiesController.text = profile.allergies;
        _diseasesController.text = profile.congenitalDiseases;
        _medicationsController.text = profile.currentMedications;
        _careNoteController.text = profile.careNote;
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
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    _allergiesController.dispose();
    _diseasesController.dispose();
    _medicationsController.dispose();
    _careNoteController.dispose();
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
      context.goBack(AppRoutes.profile);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final profile = _profile;
    if (profile == null) return;

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    final updated = profile.copyWith(
      emergencyContactName: _emergencyNameController.text.trim(),
      emergencyContactPhone: _emergencyPhoneController.text.trim(),
      emergencyContactRelationship: _emergencyRelationship,
      bloodType: _bloodType,
      allergies: _allergiesController.text.trim(),
      congenitalDiseases: _diseasesController.text.trim(),
      currentMedications: _medicationsController.text.trim(),
      careNote: _careNoteController.text.trim(),
    );

    try {
      await ref.read(profileRepositoryProvider).update(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _saveError = friendlyErrorMessage(e);
      });
      return;
    }

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _dirty = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกข้อมูลสุขภาพเรียบร้อยแล้ว')),
    );
    context.goBack(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ข้อมูลสุขภาพ'),
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
        title: const Text('ข้อมูลสุขภาพ'),
        leading: BackButton(onPressed: _handleBack),
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
                title: 'ผู้ติดต่อฉุกเฉิน',
                subtitle: 'ใช้ติดต่อกรณีฉุกเฉินระหว่างการใช้บริการ',
                icon: Icons.emergency_share_rounded,
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    AppTextField(
                      controller: _emergencyNameController,
                      label: 'ชื่อผู้ติดต่อฉุกเฉิน',
                      prefixIcon: Icons.person_outline,
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _emergencyPhoneController,
                      label: 'เบอร์โทรผู้ติดต่อฉุกเฉิน',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
                      onChanged: (_) => _markDirty(),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        if (!RegExp(r'^0[0-9]{8,9}$').hasMatch(v.trim())) {
                          return 'เบอร์โทรไม่ถูกต้อง';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<String>(
                      initialValue: _emergencyRelationship.isEmpty
                          ? null
                          : _emergencyRelationship,
                      decoration: const InputDecoration(
                        labelText: 'ความสัมพันธ์',
                        prefixIcon: Icon(Icons.diversity_3_outlined),
                      ),
                      items: _relationships
                          .map(
                            (r) => DropdownMenuItem(value: r, child: Text(r)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _emergencyRelationship =
                            v ?? _emergencyRelationship;
                        _dirty = true;
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'ข้อมูลสุขภาพพื้นฐาน',
                subtitle: 'ช่วยให้พาร์ทเนอร์ดูแลคุณได้อย่างเหมาะสม',
                icon: Icons.medical_information_rounded,
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _bloodType.isEmpty ? null : _bloodType,
                      decoration: const InputDecoration(
                        labelText: 'กรุ๊ปเลือด',
                        prefixIcon: Icon(Icons.bloodtype_outlined),
                      ),
                      items: _bloodTypes
                          .map(
                            (b) => DropdownMenuItem(value: b, child: Text(b)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _bloodType = v ?? _bloodType;
                        _dirty = true;
                      }),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _allergiesController,
                      label: 'ประวัติการแพ้',
                      hint: 'เช่น แพ้อาหารทะเล, แพ้ยาปฏิชีวนะ',
                      maxLines: 2,
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _diseasesController,
                      label: 'โรคประจำตัว',
                      hint: 'เช่น ความดันโลหิตสูง, เบาหวาน',
                      maxLines: 2,
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _medicationsController,
                      label: 'ยาที่ใช้ประจำ',
                      hint: 'เช่น ยาลดความดัน (เช้า-เย็น)',
                      maxLines: 2,
                      onChanged: (_) => _markDirty(),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _careNoteController,
                      label: 'หมายเหตุการดูแล',
                      hint: 'ข้อมูลอื่น ๆ ที่ผู้ดูแลควรทราบ',
                      maxLines: 4,
                      onChanged: (_) => _markDirty(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  'ข้อมูลสุขภาพของคุณจะถูกเก็บเป็นความลับและใช้เพื่อการดูแลที่ปลอดภัยเท่านั้น',
                  style: Theme.of(context).textTheme.bodySmall,
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
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล',
                icon: Icons.save_rounded,
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
