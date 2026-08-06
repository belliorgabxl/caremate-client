import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/aurora_background.dart';
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
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  final _allergiesController = TextEditingController();
  final _diseasesController = TextEditingController();
  final _medicationsController = TextEditingController();
  final _careNoteController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
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

    final profile = await ref.read(profileRepositoryProvider).getForUser(user);
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
    });
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

  Future<void> _save() async {
    final profile = _profile;
    if (profile == null) return;

    setState(() => _isSaving = true);

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

    await ref.read(profileRepositoryProvider).update(updated);

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('บันทึกข้อมูลสุขภาพเรียบร้อยแล้ว')),
    );
    context.go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('ข้อมูลสุขภาพ'),
          leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ข้อมูลสุขภาพ'),
        leading: BackButton(onPressed: () => context.go(AppRoutes.profile)),
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
          ListView(
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
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _emergencyPhoneController,
                      label: 'เบอร์โทรผู้ติดต่อฉุกเฉิน',
                      prefixIcon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      maxLength: 10,
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
                      onChanged: (v) => setState(
                        () => _emergencyRelationship =
                            v ?? _emergencyRelationship,
                      ),
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
                      onChanged: (v) =>
                          setState(() => _bloodType = v ?? _bloodType),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _allergiesController,
                      label: 'ประวัติการแพ้',
                      hint: 'เช่น แพ้อาหารทะเล, แพ้ยาปฏิชีวนะ',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _diseasesController,
                      label: 'โรคประจำตัว',
                      hint: 'เช่น ความดันโลหิตสูง, เบาหวาน',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _medicationsController,
                      label: 'ยาที่ใช้ประจำ',
                      hint: 'เช่น ยาลดความดัน (เช้า-เย็น)',
                      maxLines: 2,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      controller: _careNoteController,
                      label: 'หมายเหตุการดูแล',
                      hint: 'ข้อมูลอื่น ๆ ที่ผู้ดูแลควรทราบ',
                      maxLines: 4,
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
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isSaving ? 'กำลังบันทึก...' : 'บันทึกข้อมูล',
                icon: Icons.save_rounded,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
