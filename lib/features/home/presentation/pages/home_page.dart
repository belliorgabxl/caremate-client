
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/models/care_member.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/section_header.dart';
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
  String? _error;
  List<CareMember> _members = const [];
  List<Booking> _activeBookings = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final members = await ref.read(memberRepositoryProvider).list();
      final bookings = await ref
          .read(bookingRepositoryProvider)
          .getActiveBookings();

      if (!mounted) return;
      setState(() {
        _members = members;
        _activeBookings = bookings;
        _isLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _isLoading = false;
      });
    }
  }

  List<Booking> get _pendingPaymentBookings => _activeBookings
      .where((b) => b.status == BookingStatus.awaitingPayment)
      .toList();

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final pendingPayments = _pendingPaymentBookings;
    final hasPendingPayment = pendingPayments.isNotEmpty;
    final hasActiveBooking = _activeBookings.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareMate'),
        actions: [
          IconButton(
            onPressed: () => context.go(AppRoutes.bookingHistory),
            icon: const Icon(Icons.history_rounded),
            tooltip: 'ประวัติการจอง',
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? ListView(
              padding: const EdgeInsets.fromLTRB(20, 40, 20, 32),
              children: [
                EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'โหลดข้อมูลไม่สำเร็จ',
                  message: _error!,
                  action: PrimaryButton(
                    label: 'ลองอีกครั้ง',
                    icon: Icons.refresh_rounded,
                    expanded: false,
                    onPressed: _load,
                  ),
                ),
              ],
            )
          : Stack(
              children: [
                const Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: AuroraBackground(),
                ),
                RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
                    children: [
                      Text(
                        'สวัสดี, ${user?.displayName ?? 'ผู้ใช้งาน'}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'วันนี้อยากให้ CareMate ดูแลด้านไหนดี?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppRadius.sm,),
                                ),
                              ),
                              onPressed: () => context.go(AppRoutes.booking),
                              icon: const Icon(Icons.add_circle_rounded),
                              label: const Text('จองบริการ'),
                            ),
                          ),
                          const SizedBox(width: 12),

                          IconButton.filled(
                            onPressed: () => context.go(AppRoutes.members),
                            icon: const Icon(Icons.groups_rounded),
                            tooltip: 'สมาชิกที่ดูแล',
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.onPrimaryContainer,
                              minimumSize: const Size(56, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _StatsCard(
                        memberCount: _members.length,
                        bookingCount: _activeBookings.length,
                        pendingPaymentCount: pendingPayments.length,
                      ),
                      const SizedBox(height: 28),

                      // Urgent-first: whichever needs the user's attention leads.
                      if (hasPendingPayment) ...[
                        SectionHeader(
                          title: 'การชำระเงิน',
                          subtitle: 'สรุปรายการชำระเงินล่าสุด',
                          actionText: 'ดูเพิ่ม',
                          onActionTap: () => context.go(AppRoutes.payment),
                        ),
                        const SizedBox(height: 12),
                        _PaymentSummaryCard(pendingBookings: pendingPayments),
                        const SizedBox(height: 28),
                      ],
                      if (hasActiveBooking) ...[
                        SectionHeader(
                          title: 'นัดหมายล่าสุด',
                          subtitle: 'รายการจองที่กำลังจะมาถึง',
                          actionText: 'ดูรายการ',
                          onActionTap: () => context.go(AppRoutes.booking),
                        ),
                        const SizedBox(height: 12),
                        _UpcomingBookingCard(
                          booking: _activeBookings.first,
                          // Only glass when it's the first hero card below
                          // the stats card — with a pending payment above
                          // it, this card sits past the AuroraBackground's
                          // fixed extent and would frost plain background.
                          glass: !hasPendingPayment,
                        ),
                        const SizedBox(height: 28),
                      ] else ...[
                        SectionHeader(
                          title: 'นัดหมายล่าสุด',
                          subtitle: 'รายการจองที่กำลังจะมาถึง',
                        ),
                        const SizedBox(height: 12),
                        EmptyState(
                          icon: Icons.event_available_rounded,
                          title: 'ยังไม่มีนัดหมาย',
                          message: 'จองบริการใหม่เพื่อเริ่มดูแลคนที่คุณรัก',
                          action: FilledButton.icon(
                            onPressed: () => context.go(AppRoutes.booking),
                            icon: const Icon(Icons.add),
                            label: const Text('จองบริการ'),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                      if (!hasPendingPayment) ...[
                        SectionHeader(
                          title: 'การชำระเงิน',
                          subtitle: 'สรุปรายการชำระเงินล่าสุด',
                        ),
                        const SizedBox(height: 12),
                        const EmptyState(
                          icon: Icons.verified_rounded,
                          title: 'ไม่มีรายการค้างชำระ',
                          message: 'คุณชำระเงินครบทุกรายการแล้ว',
                        ),
                        const SizedBox(height: 28),
                      ],

                      SectionHeader(
                        title: 'บริการด่วน',
                        subtitle: 'เลือกสิ่งที่ต้องการให้ CareMate ช่วยดูแล',
                        actionText: 'ทั้งหมด',
                        onActionTap: () => context.go(AppRoutes.booking),
                      ),
                      const SizedBox(height: 12),
                      const _QuickActionsGrid(),
                      const SizedBox(height: 28),

                      SectionHeader(
                        title: 'สมาชิกที่ดูแล',
                        subtitle: 'เลือกสมาชิกเพื่อจองบริการอย่างรวดเร็ว',
                        actionText: 'จัดการ',
                        onActionTap: () => context.go(AppRoutes.members),
                      ),
                      const SizedBox(height: 12),
                      _FamilyPreview(members: _members),
                      const SizedBox(height: 28),

                      const _CareTipCard(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.memberCount,
    required this.bookingCount,
    required this.pendingPaymentCount,
  });

  final int memberCount;
  final int bookingCount;
  final int pendingPaymentCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      glass: true,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: _StatItem(
              icon: Icons.groups_rounded,
              color: AppColors.primary,
              value: '$memberCount',
              label: 'สมาชิก',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.calendar_month_rounded,
              color: AppColors.serviceHomeCare,
              value: '$bookingCount',
              label: 'นัดหมาย',
            ),
          ),
          const _StatDivider(),
          Expanded(
            child: _StatItem(
              icon: Icons.receipt_long_rounded,
              color: AppColors.warning,
              value: '$pendingPaymentCount',
              label: 'รอชำระ',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: AppColors.divider);
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        CircleIconAvatar(icon: icon, color: color, radius: 18, iconSize: 18),
        const SizedBox(height: 8),
        Text(value, style: textTheme.titleLarge),
        const SizedBox(height: 2),
        Text(label, style: textTheme.labelMedium),
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
        icon: Icons.health_and_safety_rounded,
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
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 1.22,
      ),
      itemBuilder: (context, index) {
        final action = actions[index];
        final textTheme = Theme.of(context).textTheme;

        return AppCard(
          onTap: () => context.go(action.route),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleIconAvatar(
                icon: action.icon,
                color: action.color,
                radius: 22,
              ),
              const Spacer(),
              Text(
                action.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall,
              ),
              const SizedBox(height: 3),
              Text(
                action.subtitle,
                style: textTheme.labelMedium,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  const _UpcomingBookingCard({required this.booking, this.glass = true});

  final Booking booking;
  final bool glass;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      glass: glass,
      elevated: !glass,
      padding: const EdgeInsets.all(22),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleIconAvatar(
                icon: booking.serviceIcon,
                color: booking.serviceColor,
                radius: 26,
                iconSize: 26,
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
              StatusBadge(
                text: booking.status.label,
                color: booking.status.color,
                dense: true,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
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
          const SizedBox(height: 16),
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

    final textTheme = Theme.of(context).textTheme;

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (context, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final member = members[index];

          return GestureDetector(
            onTap: () => context.go(AppRoutes.members),
            child: SizedBox(
              width: 76,
              child: Column(
                children: [
                  CircleIconAvatar(
                    icon: member.icon,
                    color: member.color,
                    radius: 30,
                    filled: true,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    member.nickname,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.labelLarge,
                  ),
                  Text(
                    member.relationship,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: textTheme.labelSmall,
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

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard({required this.pendingBookings});

  final List<Booking> pendingBookings;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final totalAmount = pendingBookings.fold<double>(
      0,
      (sum, b) => sum + b.totalAmount,
    );

    return AppCard(
      glass: true,
      padding: const EdgeInsets.all(22),
      child: Row(
        children: [
          const CircleIconAvatar(
            icon: Icons.receipt_long_rounded,
            color: AppColors.warning,
            radius: 26,
            iconSize: 26,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รอชำระ ${pendingBookings.length} รายการ',
                  style: textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  'ยอดรวม ฿${totalAmount.toStringAsFixed(0)}',
                  style: textTheme.bodySmall,
                ),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => context.go(AppRoutes.payment),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 18),
            ),
            child: const Text('ชำระ'),
          ),
        ],
      ),
    );
  }
}

class _CareTipCard extends StatelessWidget {
  const _CareTipCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(20),
      color: AppColors.primaryLight,
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
                Text(
                  'Care Tip วันนี้',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppColors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'ก่อนพาผู้สูงอายุไปโรงพยาบาล ควรเตรียมยาเดิม บัตรประชาชน และประวัติแพ้ยาไว้ให้พร้อม',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.onPrimaryContainer,
                    height: 1.45,
                  ),
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
