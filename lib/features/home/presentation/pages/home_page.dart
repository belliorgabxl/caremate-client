import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/models/care_member.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/hero_header_card.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../../shared/widgets/stat_card.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../booking/data/booking_repository.dart';
import '../../../members/data/member_repository.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  bool _isLoading = true;
  List<CareMember> _members = const [];
  List<Booking> _activeBookings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);

    final members = await ref.read(memberRepositoryProvider).list();
    final bookings = await ref.read(bookingRepositoryProvider).getActiveBookings();

    if (!mounted) return;
    setState(() {
      _members = members;
      _activeBookings = bookings;
      _isLoading = false;
    });
  }

  List<Booking> get _pendingPaymentBookings =>
      _activeBookings.where((b) => b.status == BookingStatus.awaitingPayment).toList();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareMate'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('ยังไม่มี Notification จริงในโหมดจำลอง')),
              );
            },
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
                children: [
                  HeroHeaderCard(
                    title: 'สวัสดีครับ, ${user?.displayName ?? 'ผู้ใช้งาน'}',
                    subtitle: 'วันนี้ต้องการให้ CareMate ช่วยดูแลอะไรครับ?',
                    leadingIcon: Icons.health_and_safety_rounded,
                    actions: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            onPressed: () => context.go(AppRoutes.booking),
                            icon: const Icon(Icons.add_circle_rounded),
                            label: const Text('จองบริการ'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: IconButton(
                            onPressed: () => context.go(AppRoutes.members),
                            icon: const Icon(Icons.groups_rounded, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _QuickStatsSection(
                    memberCount: _members.length,
                    bookingCount: _activeBookings.length,
                    pendingPaymentCount: _pendingPaymentBookings.length,
                  ),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'บริการด่วน',
                    subtitle: 'เลือกสิ่งที่ต้องการให้ CareMate ช่วยดูแล',
                    actionText: 'ทั้งหมด',
                    onActionTap: () => context.go(AppRoutes.booking),
                  ),
                  const SizedBox(height: 12),
                  const _QuickActionsGrid(),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'นัดหมายล่าสุด',
                    subtitle: 'รายการจองที่กำลังจะมาถึง',
                    actionText: 'ดูรายการ',
                    onActionTap: () => context.go(AppRoutes.booking),
                  ),
                  const SizedBox(height: 12),
                  _UpcomingBookingSection(bookings: _activeBookings),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'สมาชิกที่ดูแล',
                    subtitle: 'เลือกสมาชิกเพื่อจองบริการอย่างรวดเร็ว',
                    actionText: 'จัดการ',
                    onActionTap: () => context.go(AppRoutes.members),
                  ),
                  const SizedBox(height: 12),
                  _FamilyPreview(members: _members),
                  const SizedBox(height: 24),
                  SectionHeader(
                    title: 'การชำระเงิน',
                    subtitle: 'สรุปรายการชำระเงินล่าสุด',
                    actionText: 'ดูเพิ่ม',
                    onActionTap: () => context.go(AppRoutes.payment),
                  ),
                  const SizedBox(height: 12),
                  _PaymentSummarySection(pendingBookings: _pendingPaymentBookings),
                  const SizedBox(height: 24),
                  const _CareTipsCard(),
                ],
              ),
            ),
    );
  }
}

class _QuickStatsSection extends StatelessWidget {
  const _QuickStatsSection({
    required this.memberCount,
    required this.bookingCount,
    required this.pendingPaymentCount,
  });

  final int memberCount;
  final int bookingCount;
  final int pendingPaymentCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: '$memberCount',
            subtitle: 'สมาชิก',
            icon: Icons.people_alt_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: '$bookingCount',
            subtitle: 'นัดหมาย',
            icon: Icons.calendar_month_rounded,
            color: AppColors.serviceHomeCare,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: StatCard(
            title: '$pendingPaymentCount',
            subtitle: 'รอชำระ',
            icon: Icons.receipt_long_rounded,
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _HomeAction(
        icon: Icons.local_hospital_rounded,
        title: 'รับ-ส่งพบแพทย์',
        subtitle: 'มีผู้ช่วยดูแล',
        color: AppColors.serviceTransport,
        route: AppRoutes.booking,
      ),
      _HomeAction(
        icon: Icons.volunteer_activism_rounded,
        title: 'ดูแลรายชั่วโมง',
        subtitle: 'ที่บ้าน / คอนโด',
        color: AppColors.serviceHomeCare,
        route: AppRoutes.booking,
      ),
      _HomeAction(
        icon: Icons.medication_rounded,
        title: 'ซื้อยา',
        subtitle: 'ยาและเวชภัณฑ์',
        color: AppColors.serviceMedication,
        route: AppRoutes.booking,
      ),
      _HomeAction(
        icon: Icons.groups_rounded,
        title: 'สมาชิกของฉัน',
        subtitle: 'จัดการครอบครัว',
        color: AppColors.serviceErrand,
        route: AppRoutes.members,
      ),
    ];

    return GridView.builder(
      itemCount: actions.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.16,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        final textTheme = Theme.of(context).textTheme;

        return AppCard(
          onTap: () => context.go(action.route),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleIconAvatar(icon: action.icon, color: action.color, radius: 23),
              const Spacer(),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(action.subtitle, style: textTheme.labelMedium),
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingBookingSection extends StatelessWidget {
  const _UpcomingBookingSection({required this.bookings});

  final List<Booking> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.event_busy_rounded,
        title: 'ยังไม่มีนัดหมาย',
        message: 'จองบริการใหม่เพื่อเริ่มดูแลคนที่คุณรัก',
        action: FilledButton.icon(
          onPressed: () => context.go(AppRoutes.booking),
          icon: const Icon(Icons.add),
          label: const Text('จองบริการ'),
        ),
      );
    }

    final booking = bookings.first;
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              CircleIconAvatar(
                icon: booking.serviceIcon,
                color: booking.serviceColor,
                radius: 27,
                iconSize: 30,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.serviceTitle, style: textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'ให้${booking.memberName} • ${_formatDateTime(booking.scheduledAt)}',
                      style: textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(text: booking.status.label, color: booking.status.color, dense: true),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    booking.destinationAddress == null
                        ? booking.pickupAddress
                        : '${booking.pickupAddress} → ${booking.destinationAddress}',
                    style: textTheme.bodySmall?.copyWith(height: 1.35),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(
                    AppRoutes.bookingStatusPath(booking.id),
                    extra: booking,
                  ),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('ดูรายละเอียด'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: booking.status == BookingStatus.awaitingPayment
                    ? FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.payment),
                        icon: const Icon(Icons.payment_rounded),
                        label: const Text('ชำระเงิน'),
                      )
                    : FilledButton.icon(
                        onPressed: () => context.go(AppRoutes.booking),
                        icon: const Icon(Icons.add),
                        label: const Text('จองเพิ่ม'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    const months = [
      'ม.ค.', 'ก.พ.', 'มี.ค.', 'เม.ย.', 'พ.ค.', 'มิ.ย.',
      'ก.ค.', 'ส.ค.', 'ก.ย.', 'ต.ค.', 'พ.ย.', 'ธ.ค.',
    ];
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '${dateTime.day} ${months[dateTime.month - 1]} $hour:$minute น.';
  }
}

class _FamilyPreview extends StatelessWidget {
  const _FamilyPreview({required this.members});

  final List<CareMember> members;

  @override
  Widget build(BuildContext context) {
    if (members.isEmpty) {
      return const EmptyState(
        icon: Icons.people_outline_rounded,
        title: 'ยังไม่มีสมาชิก',
        message: 'เพิ่มสมาชิกที่คุณดูแลเพื่อเริ่มจองบริการ',
      );
    }

    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (context, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final member = members[index];
          final textTheme = Theme.of(context).textTheme;

          return SizedBox(
            width: 104,
            child: AppCard(
              padding: const EdgeInsets.all(12),
              onTap: () => context.go(AppRoutes.members),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleIconAvatar(icon: member.icon, color: member.color, radius: 25),
                  const SizedBox(height: 10),
                  Text(
                    member.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.relationship,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.labelMedium,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PaymentSummarySection extends StatelessWidget {
  const _PaymentSummarySection({required this.pendingBookings});

  final List<Booking> pendingBookings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (pendingBookings.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_outline_rounded,
        title: 'ไม่มีรายการค้างชำระ',
        message: 'คุณชำระเงินครบทุกรายการแล้ว',
      );
    }

    final totalAmount = pendingBookings.fold<double>(0, (sum, b) => sum + b.totalAmount);

    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          const CircleIconAvatar(
            icon: Icons.payment_rounded,
            color: AppColors.warning,
            radius: 27,
            iconSize: 30,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('รอชำระ ${pendingBookings.length} รายการ', style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text('ยอดรวม ฿${totalAmount.toStringAsFixed(0)}', style: textTheme.bodySmall),
              ],
            ),
          ),
          IconButton(
            onPressed: () => context.go(AppRoutes.payment),
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }
}

class _CareTipsCard extends StatelessWidget {
  const _CareTipsCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(18),
      color: AppColors.primaryLight.withValues(alpha: 0.35),
      borderColor: AppColors.primaryLight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleIconAvatar(
            icon: Icons.tips_and_updates_rounded,
            color: AppColors.primary,
            filled: true,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Care Tip วันนี้', style: textTheme.titleSmall),
                const SizedBox(height: 6),
                Text(
                  'ก่อนพาผู้สูงอายุไปโรงพยาบาล ควรเตรียมยาเดิม บัตรประชาชน และประวัติแพ้ยาไว้ให้พร้อม',
                  style: textTheme.bodySmall?.copyWith(height: 1.45),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeAction {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final String route;
}
