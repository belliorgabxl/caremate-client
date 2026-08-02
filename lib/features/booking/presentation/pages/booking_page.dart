import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/models/address.dart';
import '../../../../shared/models/care_member.dart';
import '../../../../shared/models/care_service.dart';
import '../../../../shared/models/payment.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/hero_header_card.dart';
import '../../../../shared/widgets/location_picker_page.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../members/data/member_repository.dart';
import '../../../payment/data/payment_repository.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_calculations.dart';

const _stepLabels = ['บริการ', 'เวลา', 'ผู้รับบริการ', 'สถานที่', 'ยืนยัน'];

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key});

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  bool _isLoading = true;
  bool _isSubmitting = false;

  final _pageController = PageController();
  int _currentStep = 0;

  List<CareService> _services = const [];
  List<CareMember> _members = const [];
  List<PaymentMethod> _paymentMethods = const [];

  int _selectedServiceIndex = 0;
  int _selectedMemberIndex = 0;

  /// Free-form "HH:mm" range — either a quick-pick chip (e.g. "08:00-12:00")
  /// or a custom start/end chosen via `showTimePicker`, not limited to a
  /// fixed set of slots or the service's default duration.
  String _startTime = '09:00';
  String _endTime = '11:00';

  /// `showDatePicker`'s `firstDate`/`lastDate` already gives a custom range
  /// (today .. +60 days) rather than a fixed list of dates.
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));

  final _pickupController = TextEditingController();
  final _destinationController = TextEditingController();
  final _noteController = TextEditingController();

  Address? _pickupLocation;
  Address? _destinationLocation;

  final List<String> _quickTimeRanges = const [
    '08:00-12:00',
    '08:00-15:00',
    '09:00-11:00',
    '13:00-18:00',
  ];

  CareService? get _selectedService => _services.isEmpty ? null : _services[_selectedServiceIndex];

  CareMember? get _selectedMember => _members.isEmpty ? null : _members[_selectedMemberIndex];

  int _minutesOfDay(String hhmm) {
    final parts = hhmm.split(':');
    final hour = int.tryParse(parts.elementAtOrNull(0) ?? '') ?? 0;
    final minute = int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0;
    return hour * 60 + minute;
  }

  /// Minutes between `_startTime` and `_endTime`; 0 if the range is invalid
  /// (end not after start) so fee/summary fall back gracefully instead of
  /// showing a negative duration.
  int get _selectedDurationMinutes {
    final minutes = _minutesOfDay(_endTime) - _minutesOfDay(_startTime);
    return minutes > 0 ? minutes : 0;
  }

  bool get _isTimeRangeValid => _selectedDurationMinutes > 0;

  /// Only PromptPay is wired up on this booking form (see `PaymentPage`'s QR
  /// step) — `paymentMethodId` sent to `POST /bookings/create` must be the
  /// real UUID from `GET /payments/methods`, not the "promptpay" slug.
  String? get _promptPayMethodId {
    for (final method in _paymentMethods) {
      if (method.slug == 'qr_promptpay') return method.id;
    }
    return null;
  }

  double get _estimatedFee {
    final service = _selectedService;
    if (service == null || !_isTimeRangeValid) return 0;
    return calculateTotal(baseFeePerHour: service.baseFeePerHour, durationMinutes: _selectedDurationMinutes);
  }

  double get _estimatedDistanceKm {
    final pickup = _pickupLocation;
    final destination = _destinationLocation;
    if (pickup?.hasCoordinates != true || destination?.hasCoordinates != true) return 0;

    const earthRadiusKm = 6371.0;
    final lat1 = pickup!.latitude! * math.pi / 180;
    final lat2 = destination!.latitude! * math.pi / 180;
    final dLat = (destination.latitude! - pickup.latitude!) * math.pi / 180;
    final dLng = (destination.longitude! - pickup.longitude!) * math.pi / 180;

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
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
    final paymentMethods = await ref.read(paymentRepositoryProvider).getMethods();

    if (!mounted) return;
    setState(() {
      _services = services;
      _members = members;
      _paymentMethods = paymentMethods;
      _pickupController.text = members.isNotEmpty ? members.first.address.addressLine : '';
      _pickupLocation = members.isNotEmpty ? members.first.address : null;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Column(
              children: [
                if (_currentStep == 0) ...[
                  _buildHeroCard(),
                  const SizedBox(height: 10),
                ],
                _buildStepProgress(),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildServiceStep(),
                _buildDateTimeStep(),
                _buildMemberStep(),
                _buildLocationStep(),
                _buildConfirmStep(service, member),
              ],
            ),
          ),
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
          Row(
            children: [
              for (var i = 0; i < _stepLabels.length; i++) ...[
                _MiniStep(number: '${i + 1}', label: _stepLabels[i], active: i <= _currentStep),
                if (i != _stepLabels.length - 1) _StepLine(active: i < _currentStep),
              ],
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: (_currentStep + 1) / _stepLabels.length,
              minHeight: 8,
              backgroundColor: AppColors.surfaceAlt,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepScaffold({required Widget child}) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      children: [child],
    );
  }

  Widget _buildServiceStep() {
    return _stepScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'เลือกบริการ',
            subtitle: 'เลือกประเภทบริการที่ต้องการให้ CareMate ช่วยดูแล',
            icon: Icons.medical_services_rounded,
          ),
          const SizedBox(height: 12),
          _buildServiceSelector(),
        ],
      ),
    );
  }

  Widget _buildDateTimeStep() {
    return _stepScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'วันและเวลา',
            subtitle: 'เลือกวันเวลาที่ต้องการรับบริการ หรือกำหนดเวลาเอง',
            icon: Icons.calendar_month_rounded,
          ),
          const SizedBox(height: 12),
          _buildDateTimeCard(),
        ],
      ),
    );
  }

  Widget _buildMemberStep() {
    return _stepScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'เลือกผู้รับบริการ',
            subtitle: 'เลือกว่าจะจองบริการให้ใคร',
            icon: Icons.people_alt_rounded,
          ),
          const SizedBox(height: 12),
          _buildMemberSelector(),
        ],
      ),
    );
  }

  Widget _buildLocationStep() {
    final service = _selectedService;

    return _stepScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (service != null)
            SectionHeader(
              title: 'สถานที่',
              subtitle: service.requiresDestination ? 'ระบุจุดรับและจุดหมายปลายทาง' : 'ระบุสถานที่ที่ต้องการให้ดูแล',
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
        ],
      ),
    );
  }

  Widget _buildConfirmStep(CareService? service, CareMember? member) {
    return _stepScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'ยืนยันรายการจอง',
            subtitle: 'ตรวจสอบข้อมูลก่อนสร้างรายการจอง',
            icon: Icons.assignment_turned_in_rounded,
          ),
          const SizedBox(height: 12),
          if (service != null && member != null) ...[
            _ConfirmTile(
              icon: service.icon,
              color: service.color,
              title: service.title,
              subtitle: '฿${_estimatedFee.toStringAsFixed(0)} • $_selectedDurationMinutes นาที',
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
              title: '${_formatDate(_selectedDate)} เวลา $_startTime-$_endTime',
              subtitle: 'เวลานัดหมาย',
            ),
            const SizedBox(height: 12),
            _buildSummaryCard(service, member),
          ] else
            const AppCard(child: Text('กรุณาเลือกบริการและผู้รับบริการให้ครบก่อน')),
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
              _pickupLocation = member.address;
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
    final textTheme = Theme.of(context).textTheme;
    final currentRange = '$_startTime-$_endTime';
    final isQuickRange = _quickTimeRanges.contains(currentRange);

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
                        Text('วันที่รับบริการ', style: textTheme.labelMedium),
                        const SizedBox(height: 3),
                        Text(
                          _formatDate(_selectedDate),
                          style: textTheme.titleSmall,
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
            child: Text('ช่วงเวลารับบริการ', style: textTheme.labelMedium),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _quickTimeRanges.map((range) {
                final selected = isQuickRange && currentRange == range;
                return ChoiceChip(
                  selected: selected,
                  label: Text(range),
                  onSelected: (_) {
                    final parts = range.split('-');
                    setState(() {
                      _startTime = parts[0];
                      _endTime = parts[1];
                    });
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'เวลาเริ่ม',
                  value: _startTime,
                  onTap: () => _pickRangeTime(isStart: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  label: 'เวลาสิ้นสุด',
                  value: _endTime,
                  onTap: () => _pickRangeTime(isStart: false),
                ),
              ),
            ],
          ),
          if (!_isTimeRangeValid) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'เวลาสิ้นสุดต้องมากกว่าเวลาเริ่ม',
                style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
            ),
          ],
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
            suffixIcon: IconButton(
              tooltip: 'เลือกบนแผนที่',
              icon: const Icon(Icons.map_rounded),
              onPressed: () => _pickLocationOnMap(isPickup: true),
            ),
          ),
          if (requiresDestination) ...[
            const SizedBox(height: 14),
            AppTextField(
              controller: _destinationController,
              label: 'จุดหมายปลายทาง',
              hint: 'เช่น โรงพยาบาลสมิติเวช สุขุมวิท',
              prefixIcon: Icons.flag_rounded,
              suffixIcon: IconButton(
                tooltip: 'เลือกบนแผนที่',
                icon: const Icon(Icons.map_rounded),
                onPressed: () => _pickLocationOnMap(isPickup: false),
              ),
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
                      'ระยะทางประมาณ ${_estimatedDistanceKm.toStringAsFixed(1)} กม. • ใช้เวลาประมาณ $_selectedDurationMinutes นาที',
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
          _SummaryRow(label: 'วันเวลา', value: '${_formatDate(_selectedDate)} $_startTime-$_endTime'),
          _SummaryRow(
            label: 'ระยะทาง',
            value: service.requiresDestination ? '${_estimatedDistanceKm.toStringAsFixed(1)} กม.' : '-',
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
    final isLastStep = _currentStep == _stepLabels.length - 1;
    final canInteract = _selectedService != null && !_isSubmitting;

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
            if (_currentStep > 0) ...[
              SizedBox(
                width: 52,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isSubmitting ? null : _goToPreviousStep,
                  style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
                  child: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(width: 12),
            ],
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
                label: isLastStep ? 'ยืนยันและไปชำระเงิน' : 'ถัดไป',
                icon: isLastStep ? Icons.payment_rounded : null,
                isLoading: _isSubmitting,
                onPressed: canInteract ? (isLastStep ? _confirmAndSubmit : _goToNextStep) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 280), curve: Curves.easeOut);
  }

  void _goToPreviousStep() {
    if (_currentStep == 0) return;
    _goToStep(_currentStep - 1);
  }

  void _goToNextStep() {
    // Step index 2 = "ผู้รับบริการ" (recipient), 3 = "สถานที่" (location).
    if (_currentStep == 2 && _members.isEmpty) {
      _showSnack('กรุณาเพิ่มสมาชิกก่อนทำการจอง');
      return;
    }
    if (_currentStep == 3) {
      if (_pickupLocation?.hasCoordinates != true) {
        _showSnack('กรุณาเลือกจุดรับบนแผนที่');
        return;
      }
      final service = _selectedService;
      if (service != null && service.requiresDestination && _destinationLocation?.hasCoordinates != true) {
        _showSnack('กรุณาเลือกจุดหมายปลายทางบนแผนที่');
        return;
      }
    }

    if (_currentStep < _stepLabels.length - 1) {
      _goToStep(_currentStep + 1);
    }
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

  Future<void> _pickRangeTime({required bool isStart}) async {
    final current = isStart ? _startTime : _endTime;
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.tryParse(parts.elementAtOrNull(0) ?? '') ?? TimeOfDay.now().hour,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
    );

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;

    final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    setState(() {
      if (isStart) {
        _startTime = formatted;
      } else {
        _endTime = formatted;
      }
    });
  }

  Future<void> _pickLocationOnMap({required bool isPickup}) async {
    final current = isPickup ? _pickupLocation : _destinationLocation;

    final picked = await Navigator.of(context).push<Address>(
      MaterialPageRoute(
        builder: (context) => LocationPickerPage(
          title: isPickup ? 'เลือกจุดรับ' : 'เลือกจุดหมายปลายทาง',
          initialAddress: current,
        ),
      ),
    );

    if (picked == null || !mounted) return;

    setState(() {
      if (isPickup) {
        _pickupLocation = picked;
        _pickupController.text = picked.addressLine;
      } else {
        _destinationLocation = picked;
        _destinationController.text = picked.addressLine;
      }
    });
  }

  Future<void> _confirmAndSubmit() async {
    final service = _selectedService;
    final member = _selectedMember;
    if (service == null || member == null) return;

    await _submitBooking(service, member);
  }

  Future<void> _submitBooking(CareService service, CareMember member) async {
    if (_pickupLocation?.hasCoordinates != true) {
      _showSnack('กรุณาเลือกจุดรับบนแผนที่');
      return;
    }
    if (service.requiresDestination && _destinationLocation?.hasCoordinates != true) {
      _showSnack('กรุณาเลือกจุดหมายปลายทางบนแผนที่');
      return;
    }
    if (!_isTimeRangeValid) {
      _showSnack('เวลาสิ้นสุดต้องมากกว่าเวลาเริ่ม');
      return;
    }
    final paymentMethodId = _promptPayMethodId;
    if (paymentMethodId == null) {
      _showSnack('ไม่พบวิธีชำระเงิน PromptPay กรุณาลองใหม่อีกครั้ง');
      return;
    }

    setState(() => _isSubmitting = true);

    final startParts = _startTime.split(':');
    final endParts = _endTime.split(':');
    final scheduledAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(startParts[0]),
      int.parse(startParts[1]),
    );
    final scheduledEndAt = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      int.parse(endParts[0]),
      int.parse(endParts[1]),
    );

    final pickup = _pickupLocation!.copyWith(addressLine: _pickupController.text.trim());
    final destination = service.requiresDestination
        ? _destinationLocation!.copyWith(addressLine: _destinationController.text.trim())
        : null;

    await ref.read(bookingRepositoryProvider).createBooking(
          service: service,
          member: member,
          scheduledAt: scheduledAt,
          scheduledEndAt: scheduledEndAt,
          pickupAddress: pickup,
          destinationAddress: destination,
          notes: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
          paymentMethodId: paymentMethodId,
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

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: textTheme.labelSmall),
                  Text(value, style: textTheme.titleSmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  T? elementAtOrNull(int index) => index >= 0 && index < length ? this[index] : null;
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
