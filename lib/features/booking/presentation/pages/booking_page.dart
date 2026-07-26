import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/models/care_member.dart';
import '../../../../shared/models/care_service.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/hero_header_card.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../members/data/member_repository.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_calculations.dart';

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<CareService> _services = const [];
  List<CareMember> _members = const [];

  int _selectedServiceIndex = 0;
  int _selectedMemberIndex = 0;
  int _selectedTimeIndex = 1;

  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _noteController = TextEditingController();

  final List<String> _timeSlots = const [
    '08:00',
    '09:30',
    '11:00',
    '13:00',
    '15:30',
    '18:00',
  ];

  CareService? get _selectedService => _services.isEmpty ? null : _services[_selectedServiceIndex];

  CareMember? get _selectedMember => _members.isEmpty ? null : _members[_selectedMemberIndex];

  String get _selectedTime => _timeSlots[_selectedTimeIndex];

  double get _estimatedFee {
    final service = _selectedService;
    if (service == null) return 0;
    return calculateTotal(baseFeePerHour: service.baseFeePerHour, durationMinutes: service.durationMinutes);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final services = await ref.read(bookingRepositoryProvider).getServices();
    final members = await ref.read(memberRepositoryProvider).list();

    if (!mounted) return;
    setState(() {
      _services = services;
      _members = members;
      _pickupController.text = members.isNotEmpty ? members.first.address.addressLine : '';
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pickupController.dispose();
    _destinationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Booking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final service = _selectedService;
    final member = _selectedMember;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      bottomNavigationBar: _buildBottomBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          _buildHeroCard(),
          const SizedBox(height: 18),
          _buildStepProgress(),
          const SizedBox(height: 22),
          const SectionHeader(
            title: 'เลือกบริการ',
            subtitle: 'เลือกประเภทบริการที่ต้องการให้ CareMate ช่วยดูแล',
            icon: Icons.medical_services_rounded,
          ),
          const SizedBox(height: 12),
          _buildServiceSelector(),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'เลือกผู้รับบริการ',
            subtitle: 'เลือกว่าจะจองบริการให้ใคร',
            icon: Icons.people_alt_rounded,
          ),
          const SizedBox(height: 12),
          _buildMemberSelector(),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'วันและเวลา',
            subtitle: 'เลือกวันเวลาที่ต้องการรับบริการ',
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 12),
          _buildDateTimeCard(),
          const SizedBox(height: 24),
          if (service != null)
            SectionHeader(
              title: 'สถานที่',
              subtitle:
                  service.requiresDestination ? 'ระบุจุดรับและจุดหมายปลายทาง' : 'ระบุสถานที่ที่ต้องการให้ดูแล',
              icon: Icons.location_on_rounded,
            ),
          const SizedBox(height: 12),
          _buildLocationCard(),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'ข้อมูลเพิ่มเติม',
            subtitle: 'หมายเหตุสำหรับพาร์ทเนอร์ก่อนเริ่มงาน',
            icon: Icons.note_alt_rounded,
          ),
          const SizedBox(height: 12),
          _buildNoteCard(),
          const SizedBox(height: 24),
          if (service != null && member != null) _buildSummaryCard(service, member),
        ],
      ),
    );
  }

  Widget _buildHeroCard() {
    return const HeroHeaderCard(
      title: 'จองบริการดูแลสุขภาพ',
      subtitle: 'เลือกบริการ ผู้รับบริการ วันเวลา และสถานที่ จากนั้นระบบจะสรุปราคาให้ก่อนยืนยัน',
      leadingIcon: Icons.health_and_safety_rounded,
    );
  }

  Widget _buildStepProgress() {
    return AppCard(
      child: Column(
        children: [
          const Row(
            children: [
              _MiniStep(number: '1', label: 'บริการ', active: true),
              _StepLine(active: true),
              _MiniStep(number: '2', label: 'เวลา', active: true),
              _StepLine(active: true),
              _MiniStep(number: '3', label: 'สถานที่', active: true),
              _StepLine(active: false),
              _MiniStep(number: '4', label: 'ยืนยัน', active: false),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: const LinearProgressIndicator(
              value: 0.78,
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelector() {
    return SizedBox(
      height: 176,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _services.length,
        separatorBuilder: (context, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final service = _services[index];
          final selected = _selectedServiceIndex == index;
          final textTheme = Theme.of(context).textTheme;

          return GestureDetector(
            onTap: () => setState(() => _selectedServiceIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 178,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selected ? service.color : AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: selected ? service.color : AppColors.border,
                  width: selected ? 1.6 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: selected
                        ? Colors.white.withValues(alpha: 0.22)
                        : service.color.withValues(alpha: 0.12),
                    child: Icon(
                      service.icon,
                      color: selected ? Colors.white : service.color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    service.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      color: selected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: selected ? Colors.white.withValues(alpha: 0.86) : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMemberSelector() {
    if (_members.isEmpty) {
      return const AppCard(child: Text('ยังไม่มีสมาชิก กรุณาเพิ่มสมาชิกก่อนทำการจอง'));
    }

    return Column(
      children: _members.asMap().entries.map((entry) {
        final index = entry.key;
        final member = entry.value;
        final selected = _selectedMemberIndex == index;
        final textTheme = Theme.of(context).textTheme;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AppCard(
            borderColor: selected ? AppColors.primary : AppColors.border,
            onTap: () => setState(() {
              _selectedMemberIndex = index;
              _pickupController.text = member.address.addressLine;
            }),
            child: Row(
              children: [
                CircleIconAvatar(icon: member.icon, color: member.color, radius: 28, iconSize: 30),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.nickname, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text('${member.relationship} • ${member.age} ปี', style: textTheme.bodySmall),
                      const SizedBox(height: 7),
                      Text(
                        member.careNote,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? AppColors.primary : AppColors.border,
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDateTimeCard() {
    return AppCard(
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const CircleIconAvatar(
                    icon: Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    filled: true,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('วันที่รับบริการ', style: Theme.of(context).textTheme.labelMedium),
                        const SizedBox(height: 3),
                        Text(
                          _formatDate(_selectedDate),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _timeSlots.asMap().entries.map((entry) {
                final index = entry.key;
                final time = entry.value;
                final selected = _selectedTimeIndex == index;

                return ChoiceChip(
                  selected: selected,
                  label: Text(time),
                  onSelected: (_) => setState(() => _selectedTimeIndex = index),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    final service = _selectedService;
    final requiresDestination = service?.requiresDestination ?? false;

    return AppCard(
      child: Column(
        children: [
          AppTextField(
            controller: _pickupController,
            label: requiresDestination ? 'จุดรับ' : 'สถานที่รับบริการ',
            prefixIcon: Icons.my_location_rounded,
          ),
          if (requiresDestination) ...[
            const SizedBox(height: 14),
            AppTextField(
              controller: _destinationController,
              label: 'จุดหมายปลายทาง',
              hint: 'เช่น โรงพยาบาลสมิติเวช สุขุมวิท',
              prefixIcon: Icons.flag_rounded,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Row(
                children: [
                  const Icon(Icons.route_rounded, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'ระยะทางประมาณ ${service!.typicalDistanceKm.toStringAsFixed(1)} กม. • ใช้เวลาประมาณ ${service.durationMinutes} นาที',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNoteCard() {
    return AppCard(
      child: AppTextField(
        controller: _noteController,
        maxLines: 4,
        hint: 'เช่น เดินช้า, ต้องใช้รถเข็น, แพ้อาหาร, ต้องช่วยถือของ',
      ),
    );
  }

  Widget _buildSummaryCard(CareService service, CareMember member) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('สรุปรายการจอง', style: textTheme.titleMedium)),
              const StatusBadge(text: 'Estimate', color: AppColors.primary),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryRow(label: 'บริการ', value: service.title),
          _SummaryRow(label: 'ผู้รับบริการ', value: member.fullName),
          _SummaryRow(label: 'วันเวลา', value: '${_formatDate(_selectedDate)} $_selectedTime'),
          _SummaryRow(
            label: 'ระยะทาง',
            value: service.requiresDestination ? '${service.typicalDistanceKm.toStringAsFixed(1)} กม.' : '-',
          ),
          const Divider(height: 24),
          Row(
            children: [
              Text('ยอดชำระโดยประมาณ', style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Text(
                '฿${_estimatedFee.toStringAsFixed(0)}',
                style: textTheme.headlineMedium?.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final textTheme = Theme.of(context).textTheme;
    final canSubmit = _selectedService != null && _selectedMember != null && !_isSubmitting;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 22),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ราคาโดยประมาณ', style: textTheme.labelMedium),
                  const SizedBox(height: 2),
                  Text('฿${_estimatedFee.toStringAsFixed(0)}', style: textTheme.headlineSmall),
                ],
              ),
            ),
            SizedBox(
              width: 190,
              child: PrimaryButton(
                label: 'ยืนยันการจอง',
                icon: Icons.check_circle_rounded,
                isLoading: _isSubmitting,
                onPressed: canSubmit ? _showConfirmSheet : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
    );

    if (pickedDate == null) return;

    setState(() {
      _selectedDate = pickedDate;
    });
  }

  void _showConfirmSheet() {
    final service = _selectedService!;
    final member = _selectedMember!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final textTheme = Theme.of(context).textTheme;

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleIconAvatar(
                icon: Icons.assignment_turned_in_rounded,
                color: AppColors.primary,
                radius: 42,
                iconSize: 42,
              ),
              const SizedBox(height: 14),
              Text('ยืนยันรายการจอง', style: textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'ตรวจสอบข้อมูลก่อนสร้างรายการจอง',
                style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              _ConfirmTile(
                icon: service.icon,
                color: service.color,
                title: service.title,
                subtitle: '฿${_estimatedFee.toStringAsFixed(0)} • ${service.durationMinutes} นาที',
              ),
              _ConfirmTile(
                icon: member.icon,
                color: member.color,
                title: member.fullName,
                subtitle: '${member.relationship} • ${member.age} ปี',
              ),
              _ConfirmTile(
                icon: Icons.schedule_rounded,
                color: AppColors.primary,
                title: '${_formatDate(_selectedDate)} เวลา $_selectedTime',
                subtitle: 'เวลานัดหมาย',
              ),
              const SizedBox(height: 18),
              PrimaryButton(
                label: 'ยืนยันและไปชำระเงิน',
                icon: Icons.payment_rounded,
                onPressed: () {
                  Navigator.pop(context);
                  _submitBooking(service, member);
                },
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('กลับไปแก้ไข'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitBooking(CareService service, CareMember member) async {
    setState(() => _isSubmitting = true);

    final timeParts = _selectedTime.split(':');
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(timeParts[0]),
      int.parse(timeParts[1]),
    );

    await ref.read(bookingRepositoryProvider).createBooking(
          service: service,
          member: member,
          scheduledAt: scheduledAt,
          pickupAddress: _pickupController.text.trim(),
          destinationAddress: _destinationController.text.trim(),
          notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          paymentMethodId: 'promptpay',
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('สร้างรายการจองสำเร็จ กรุณาชำระเงิน')),
    );
    context.go(AppRoutes.payment);
  }

  String _formatDate(DateTime date) {
    const months = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year + 543}';
  }
}

class _MiniStep extends StatelessWidget {
  const _MiniStep({
    required this.number,
    required this.label,
    required this.active,
  });

  final String number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 15,
          backgroundColor: active ? AppColors.primary : AppColors.border,
          child: Text(
            number,
            style: TextStyle(
              color: active ? Colors.white : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: active ? AppColors.primary : AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class _StepLine extends StatelessWidget {
  const _StepLine({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: active ? AppColors.primary : AppColors.border,
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmTile extends StatelessWidget {
  const _ConfirmTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          CircleIconAvatar(icon: icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall,
                ),
                const SizedBox(height: 3),
                Text(subtitle, style: textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
