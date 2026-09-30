import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/booking_wizard_dirty.dart';
import '../../../../app/router/members_dirty.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/address.dart';
import '../../../../shared/models/booking_prefill.dart';
import '../../../../shared/models/care_member.dart';
import '../../../../shared/models/care_service.dart';
import '../../../../shared/models/payment.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/hero_header_card.dart';
import '../../../../shared/widgets/location_picker_page.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../members/data/member_repository.dart';
import '../../../payment/data/payment_repository.dart';
import '../../../profile/data/profile_repository.dart';
import '../../../profile/presentation/widgets/bank_account_required_sheet.dart';
import '../../data/booking_repository.dart';
import '../../domain/booking_calculations.dart';

const _stepLabels = ['บริการ', 'เวลา', 'ผู้รับบริการ', 'สถานที่', 'ยืนยัน'];

class BookingPage extends ConsumerStatefulWidget {
  const BookingPage({super.key, this.prefill});

  final BookingPrefill? prefill;

  @override
  ConsumerState<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends ConsumerState<BookingPage> {
  bool _isLoading = true;
  String? _loadError;
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

  CareService? get _selectedService =>
      _services.isEmpty ? null : _services[_selectedServiceIndex];

  CareMember? get _selectedMember =>
      _members.isEmpty ? null : _members[_selectedMemberIndex];

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

  bool get _isDurationPositive => _selectedDurationMinutes > 0;

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// If the selected date is today, the start time can't be earlier than
  /// right now — `showDatePicker`'s `firstDate: now` only blocks past
  /// *dates*, not past *times* on today's date.
  bool get _isStartTimeInFuture {
    final now = DateTime.now();
    if (!_isSameDay(_selectedDate, now)) return true;
    return _minutesOfDay(_startTime) >= now.hour * 60 + now.minute;
  }

  bool get _isTimeRangeValid => _isDurationPositive && _isStartTimeInFuture;

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
    return calculateEstimatedTotal(
      pricingModel: service.pricingModel,
      baseFeePerHour: service.baseFeePerHour,
      ratePerKm: service.ratePerKm,
      baseFeeFirstKm: service.baseFeeFirstKm,
      durationMinutes: _selectedDurationMinutes,
      distanceKm: _estimatedDistanceKm,
    );
  }

  double get _estimatedDistanceKm {
    final pickup = _pickupLocation;
    final destination = _destinationLocation;
    if (pickup?.hasCoordinates != true || destination?.hasCoordinates != true) {
      return 0;
    }

    const earthRadiusKm = 6371.0;
    final lat1 = pickup!.latitude! * math.pi / 180;
    final lat2 = destination!.latitude! * math.pi / 180;
    final dLat = (destination.latitude! - pickup.latitude!) * math.pi / 180;
    final dLng = (destination.longitude! - pickup.longitude!) * math.pi / 180;

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  @override
  void initState() {
    super.initState();
    bookingWizardDirty.value = false;
    _load();
    membersDirty.addListener(_onMembersDirty);
  }

  /// `StatefulShellRoute.indexedStack` keeps this page alive across tab
  /// switches, so `initState`/`_load()` only ever run once per app session —
  /// without this, a member added/edited/deleted on the Members tab would
  /// never show up here. Refetches just the member list, not the whole page
  /// (services/payment methods/bank-account check), so it doesn't re-trigger
  /// the bank-account-required sheet or reset the wizard step.
  Future<void> _onMembersDirty() async {
    if (!membersDirty.value || _isLoading) return;
    membersDirty.value = false;

    try {
      final members = await ref.read(memberRepositoryProvider).list();
      if (!mounted) return;
      setState(() {
        _members = members;
        if (_selectedMemberIndex >= members.length) {
          _selectedMemberIndex = members.isEmpty ? 0 : members.length - 1;
        }
      });
    } on ApiException {
      // Best-effort — keep showing the previous list rather than erroring.
    }
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      await _loadInner();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'โหลดข้อมูลไม่สำเร็จ กรุณาลองใหม่อีกครั้ง';
      });
    }
  }

  Future<void> _loadInner() async {
    final profileRepo = ref.read(profileRepositoryProvider);
    final bankAccount = await profileRepo.getBankAccount();
    if (!mounted) return;
    if (!bankAccount.hasBankAccount) {
      final saved = await BankAccountRequiredSheet.show(
        context,
        repository: profileRepo,
      );
      if (!mounted) return;
      if (!saved) {
        // The user may already have tapped away to a different bottom tab
        // while this sheet was pending — `showModalBottomSheet` attaches to
        // the shell's own inner Navigator, not the outer one the bottom nav
        // lives in, so that tap isn't blocked by the sheet the way it looks.
        // `mounted` alone doesn't catch this (this State can still be
        // mounted when the callback resumes), so also check we're still
        // actually showing the booking route before yanking the user back
        // to Home out from under whatever tab they've since switched to.
        if (GoRouterState.of(
          context,
        ).uri.toString().startsWith(AppRoutes.booking)) {
          context.goForward(AppRoutes.home);
        }
        setState(() => _isLoading = false);
        return;
      }
    }

    final services = await ref.read(bookingRepositoryProvider).getServices();
    if (!mounted) return;
    final members = await ref.read(memberRepositoryProvider).list();
    if (!mounted) return;
    final paymentMethods = await ref
        .read(paymentRepositoryProvider)
        .getMethods();

    if (!mounted) return;
    setState(() {
      _services = services;
      _members = members;
      _paymentMethods = paymentMethods;
      _pickupController.text = members.isNotEmpty
          ? members.first.address.addressLine
          : '';
      _pickupLocation = members.isNotEmpty ? members.first.address : null;
      _isLoading = false;
    });

    _applyPrefill(services, members);
  }

  /// Best-effort — a `serviceSlug`/`memberId` that doesn't match anything in
  /// the just-loaded lists just leaves the default selection in place, and a
  /// missing pickup/destination address leaves whatever `_load()` already
  /// set. Never throws, never blocks the page.
  void _applyPrefill(List<CareService> services, List<CareMember> members) {
    final prefill = widget.prefill;
    if (prefill == null) return;

    var serviceIndex = _selectedServiceIndex;
    var memberIndex = _selectedMemberIndex;

    final slug = prefill.serviceSlug;
    if (slug != null) {
      final index = services.indexWhere((s) => s.slug == slug);
      if (index != -1) serviceIndex = index;
    }

    final memberId = prefill.memberId;
    if (memberId != null) {
      final index = members.indexWhere((m) => m.id == memberId);
      if (index != -1) memberIndex = index;
    }

    final pickup = prefill.pickupAddress;
    final destination = prefill.destinationAddress;

    setState(() {
      _selectedServiceIndex = serviceIndex;
      _selectedMemberIndex = memberIndex;
      if (pickup != null) {
        _pickupLocation = pickup;
        _pickupController.text = pickup.addressLine;
      }
      if (destination != null) {
        _destinationLocation = destination;
        _destinationController.text = destination.addressLine;
      }
    });
  }

  @override
  void dispose() {
    bookingWizardDirty.value = false;
    membersDirty.removeListener(_onMembersDirty);
    _pageController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: SafeArea(child: Center(child: CircularProgressIndicator())),
      );
    }

    final loadError = _loadError;
    if (loadError != null) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.wifi_off_rounded,
                    size: 40,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    loadError,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(label: 'ลองใหม่', onPressed: _load),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_members.isEmpty) {
      return Scaffold(body: _buildNoMemberGate());
    }

    final service = _selectedService;
    final member = _selectedMember;

    return Scaffold(
      bottomNavigationBar: _buildBottomBar(),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AuroraBackground(height: _currentStep == 0 ? 340 : 210),
          ),
          Column(
            children: [
              SafeArea(
                bottom: false,
                child: Padding(
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
        ],
      ),
    );
  }

  /// A booking always needs a care recipient, so an account with no members
  /// can't start the wizard at all — gate the whole page on adding one rather
  /// than letting the user fill three steps and hit a wall at the recipient
  /// step (which is what the `_goToNextStep` guard below used to do alone).
  Widget _buildNoMemberGate() {
    final textTheme = Theme.of(context).textTheme;

    return Stack(
      children: [
        const Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: AuroraBackground(height: 340),
        ),
        ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + 8,
            20,
            32,
          ),
          children: [
            _buildHeroCard(),
            const SizedBox(height: 16),
            AppCard(
              glass: true,
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  const CircleIconAvatar(
                    icon: Icons.group_add_rounded,
                    color: AppColors.primary,
                    radius: 32,
                    iconSize: 36,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'ยังไม่มีผู้รับบริการ',
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'การจองต้องระบุว่าจองให้ใคร '
                    'กรุณาเพิ่มสมาชิกที่ต้องการให้ดูแลก่อน จึงจะเริ่มจองบริการได้',
                    textAlign: TextAlign.center,
                    style: textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'เพิ่มสมาชิก',
                    icon: Icons.person_add_alt_1_rounded,
                    onPressed: () => context.goForward(AppRoutes.members),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return const HeroHeaderCard(
      title: 'จองบริการดูแลสุขภาพ',
      subtitle:
          'เลือกบริการ ผู้รับบริการ วันเวลา และสถานที่ จากนั้นระบบจะสรุปราคาให้ก่อนยืนยัน',
      leadingIcon: Icons.health_and_safety_rounded,
    );
  }

  Widget _buildStepProgress() {
    return AppCard(
      glass: true,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          for (var i = 0; i < _stepLabels.length; i++) ...[
            _MiniStep(
              number: '${i + 1}',
              label: _stepLabels[i],
              active: i <= _currentStep,
            ),
            if (i != _stepLabels.length - 1)
              _StepLine(active: i < _currentStep),
          ],
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
              subtitle: service.requiresDestination
                  ? 'ระบุจุดรับและจุดหมายปลายทาง'
                  : 'ระบุสถานที่ที่ต้องการให้ดูแล',
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
          if (_promptPayMethodId == null) ...[
            _buildPromptPayWarningBanner(),
            const SizedBox(height: 12),
          ],
          if (service != null && member != null)
            _buildSummaryCard(service, member)
          else
            const AppCard(
              child: Text('กรุณาเลือกบริการและผู้รับบริการให้ครบก่อน'),
            ),
        ],
      ),
    );
  }

  /// PromptPay is the only payment method wired into this form — if it isn't
  /// in the fetched list (backend misconfiguration, or the list simply
  /// hasn't loaded a matching slug), surface that here instead of only at
  /// final submit.
  Widget _buildPromptPayWarningBanner() {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.warning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'ไม่พบวิธีชำระเงิน PromptPay กรุณาลองใหม่อีกครั้งภายหลัง',
              style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
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
                      color: selected
                          ? Colors.white.withValues(alpha: 0.86)
                          : AppColors.textSecondary,
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
      return const AppCard(
        child: Text('ยังไม่มีสมาชิก กรุณาเพิ่มสมาชิกก่อนทำการจอง'),
      );
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
                CircleIconAvatar(
                  icon: member.icon,
                  color: member.color,
                  radius: 28,
                  iconSize: 30,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(member.nickname, style: textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        '${member.relationship} • ${member.age} ปี',
                        style: textTheme.bodySmall,
                      ),
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
          if (!_isDurationPositive) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'เวลาสิ้นสุดต้องมากกว่าเวลาเริ่ม',
                style: textTheme.bodySmall?.copyWith(color: AppColors.danger),
              ),
            ),
          ] else if (!_isStartTimeInFuture) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'เวลาเริ่มต้องไม่ใช่เวลาที่ผ่านมาแล้ว',
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
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
        maxLength: 500,
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
          _SummaryEntityRow(
            icon: service.icon,
            color: service.color,
            title: service.title,
            subtitle: '$_selectedDurationMinutes นาที',
          ),
          const Divider(height: 28),
          _SummaryEntityRow(
            icon: member.icon,
            color: member.color,
            title: member.fullName,
            subtitle: '${member.relationship} • ${member.age} ปี',
          ),
          const Divider(height: 28),
          _SummaryEntityRow(
            icon: Icons.schedule_rounded,
            color: AppColors.primary,
            title: '${_formatDate(_selectedDate)} เวลา $_startTime-$_endTime',
            subtitle: 'เวลานัดหมาย',
          ),
          if (service.requiresDestination) ...[
            const Divider(height: 28),
            _SummaryRow(
              label: 'ระยะทาง',
              value: '${_estimatedDistanceKm.toStringAsFixed(1)} กม.',
            ),
          ],
          const Divider(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'ยอดชำระโดยประมาณ',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
              StatusBadge(text: 'ประมาณการ', color: service.color),
              const SizedBox(width: 8),
              Text(
                '฿${_estimatedFee.toStringAsFixed(0)}',
                style: textTheme.headlineMedium?.copyWith(color: service.color),
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
                  Text(
                    '฿${_estimatedFee.toStringAsFixed(0)}',
                    style: textTheme.headlineSmall,
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 190,
              child: PrimaryButton(
                label: isLastStep ? 'ยืนยันและไปชำระเงิน' : 'ถัดไป',
                icon: isLastStep ? Icons.payment_rounded : null,
                isLoading: _isSubmitting,
                onPressed: canInteract
                    ? (isLastStep ? _confirmAndSubmit : _goToNextStep)
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToStep(int step) {
    setState(() => _currentStep = step);
    // Service selection alone (step 0) isn't worth guarding — anything past
    // it (time range, recipient, location, notes, confirm) is.
    if (step > 0) {
      bookingWizardDirty.value = true;
    }
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
    );
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
      if (service != null &&
          service.requiresDestination &&
          _destinationLocation?.hasCoordinates != true) {
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
      hour:
          int.tryParse(parts.elementAtOrNull(0) ?? '') ?? TimeOfDay.now().hour,
      minute: int.tryParse(parts.elementAtOrNull(1) ?? '') ?? 0,
    );

    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;

    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
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
    if (service.requiresDestination &&
        _destinationLocation?.hasCoordinates != true) {
      _showSnack('กรุณาเลือกจุดหมายปลายทางบนแผนที่');
      return;
    }
    if (!_isDurationPositive) {
      _showSnack('เวลาสิ้นสุดต้องมากกว่าเวลาเริ่ม');
      return;
    }
    if (!_isStartTimeInFuture) {
      _showSnack('เวลาเริ่มต้องไม่ใช่เวลาที่ผ่านมาแล้ว');
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

    final pickup = _pickupLocation!.copyWith(
      addressLine: _pickupController.text.trim(),
    );
    final destination = service.requiresDestination
        ? _destinationLocation!.copyWith(
            addressLine: _destinationController.text.trim(),
          )
        : null;

    await ref
        .read(bookingRepositoryProvider)
        .createBooking(
          service: service,
          member: member,
          scheduledAt: scheduledAt,
          scheduledEndAt: scheduledEndAt,
          pickupAddress: pickup,
          destinationAddress: destination,
          notes: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          paymentMethodId: paymentMethodId,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    bookingWizardDirty.value = false;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('สร้างรายการจองสำเร็จ กรุณาชำระเงิน')),
    );
    context.pushForward(AppRoutes.payment);
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
            const Icon(
              Icons.access_time_rounded,
              color: AppColors.primary,
              size: 20,
            ),
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
  T? elementAtOrNull(int index) =>
      index >= 0 && index < length ? this[index] : null;
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
  const _SummaryRow({required this.label, required this.value});

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
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact icon+title+subtitle row for inside [AppCard] — separated from
/// its neighbors by a `Divider`, not its own boxed background, so several
/// can sit in one card without stacking into repeated same-shape tiles.
class _SummaryEntityRow extends StatelessWidget {
  const _SummaryEntityRow({
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

    return Row(
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
    );
  }
}
