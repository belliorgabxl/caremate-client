// "Aurora Glass" home — cool-white ground, jewel-tone brand colors, blurred
// aurora blobs behind frosted-glass hero cards. See DESIGN.md for the full
// system (pinned 2026-08-05, supersedes "Premium Clinic Companion"'s One
// Blue Rule, which itself superseded the discarded "Report Book" world).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/network/api_client.dart';
import '../../../../shared/data/banner_repository.dart';
import '../../../../shared/models/banner_item.dart';
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
import '../../../notifications/data/notification_repository.dart';

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
  List<BannerItem> _banners = const [];
  int _unreadNotificationCount = 0;

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
      if (!mounted) return;
      final bookings = await ref
          .read(bookingRepositoryProvider)
          .getActiveBookings();

      if (!mounted) return;

      // Non-fatal: an announcements fetch failing must never blank the rest
      // of the home page, so it gets its own inner try/catch instead of
      // joining the outer one.
      var banners = const <BannerItem>[];
      try {
        banners = await ref.read(bannerRepositoryProvider).getActive();
      } catch (_) {
        banners = const [];
      }

      // Non-fatal for the same reason as banners: the bell badge is a nice-
      // to-have, not worth blanking the rest of the home page over.
      var unreadCount = 0;
      try {
        final (_, unread) = await ref
            .read(notificationRepositoryProvider)
            .list();
        unreadCount = unread;
      } catch (_) {
        unreadCount = 0;
      }

      if (!mounted) return;
      setState(() {
        _members = members;
        _activeBookings = bookings;
        _banners = banners;
        _unreadNotificationCount = unreadCount;
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

  List<BannerItem> get _visibleBanners {
    final banners = _banners
        .where((b) => b.isActive && b.id.isNotEmpty && b.title.isNotEmpty)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return banners;
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
                  child: AuroraBackground(height: 320),
                ),
                RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 110),
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 18),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(9),
                                child: Image.asset(
                                  'assets/images/app_icon.png',
                                  width: 26,
                                  height: 26,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'CareMate',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.2,
                                    ),
                              ),
                              const Spacer(),
                              _NotificationButton(
                                unreadCount: _unreadNotificationCount,
                                onTap: () =>
                                    context.goForward(AppRoutes.notifications),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        'สวัสดีครับ, ${user?.displayName ?? 'ผู้ใช้งาน'}',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'วันนี้ต้องการให้ CareMate ช่วยดูแลอะไรครับ?',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () => context.goForward(AppRoutes.booking),
                              icon: const Icon(Icons.add_circle_rounded),
                              label: const Text('จองบริการ'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filled(
                            onPressed: () => context.goForward(AppRoutes.members),
                            icon: const Icon(Icons.groups_rounded),
                            style: IconButton.styleFrom(
                              backgroundColor: AppColors.primaryLight,
                              foregroundColor: AppColors.onPrimaryContainer,
                              minimumSize: const Size(56, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  AppRadius.md,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_visibleBanners.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        const SectionHeader(
                          title: 'ประกาศ',
                          subtitle: 'ข่าวสารและโปรโมชันล่าสุดจาก CareMate',
                          icon: Icons.campaign_rounded,
                        ),
                        const SizedBox(height: 12),
                        _BannerCarousel(banners: _visibleBanners),
                      ],
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
                          onActionTap: () => context.goForward(AppRoutes.payment),
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
                          onActionTap: () => context.goForward(AppRoutes.booking),
                        ),
                        const SizedBox(height: 12),
                        _UpcomingBookingCard(booking: _activeBookings.first),
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
                            onPressed: () => context.goForward(AppRoutes.booking),
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
                        onActionTap: () => context.goForward(AppRoutes.booking),
                      ),
                      const SizedBox(height: 12),
                      const _QuickActionsGrid(),
                      const SizedBox(height: 28),

                      SectionHeader(
                        title: 'สมาชิกที่ดูแล',
                        subtitle: 'เลือกสมาชิกเพื่อจองบริการอย่างรวดเร็ว',
                        actionText: 'จัดการ',
                        onActionTap: () => context.goForward(AppRoutes.members),
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
          onTap: () => context.goForward(action.route),
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
  const _UpcomingBookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      glass: true,
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
                  onPressed: () => context.goForward(
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
                        onPressed: () => context.goForward(AppRoutes.payment),
                        icon: const Icon(Icons.payment_rounded),
                        label: const Text('ชำระเงิน'),
                      )
                    : FilledButton.icon(
                        onPressed: () => context.goForward(AppRoutes.booking),
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
            onTap: () => context.goForward(AppRoutes.members),
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
            onPressed: () => context.goForward(AppRoutes.payment),
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

/// Horizontally-scrollable announcements strip — a distinct "announcements"
/// section rather than blending into the plain-white cards used elsewhere on
/// this page (per DESIGN.md's "glass only where it reveals real color behind
/// it" rule, these stay flat `AppCard`s, no `glass:`/aurora tie-in, since
/// they sit below the hero region).
class _BannerCarousel extends StatelessWidget {
  const _BannerCarousel({required this.banners});

  final List<BannerItem> banners;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 148,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: banners.length,
        separatorBuilder: (context, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _BannerCard(banner: banners[index]),
      ),
    );
  }
}

class _BannerCard extends StatelessWidget {
  const _BannerCard({required this.banner});

  final BannerItem banner;

  Future<void> _openLink() async {
    final linkUrl = banner.linkUrl;
    if (linkUrl == null || linkUrl.isEmpty) return;
    final uri = Uri.tryParse(linkUrl);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final hasLink = banner.linkUrl != null && banner.linkUrl!.isNotEmpty;

    return SizedBox(
      width: 260,
      child: AppCard(
        onTap: hasLink ? _openLink : null,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleIconAvatar(
                  icon: Icons.campaign_rounded,
                  color: AppColors.primary,
                  radius: 18,
                  iconSize: 18,
                ),
                if (hasLink) ...[
                  const Spacer(),
                  const Icon(
                    Icons.open_in_new_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            Text(
              banner.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.titleSmall,
            ),
            if (banner.body != null && banner.body!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Expanded(
                child: Text(
                  banner.body!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
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

/// Header notification bell — real depth (soft colored shadow + fine ring)
/// instead of the flat tinted-square default `IconButton`, matching the
/// rest of the app's icon-badge language (see [CircleIconAvatar]'s own
/// doc). Custom rather than [CircleIconAvatar] itself since this one needs
/// a tap target.
class _NotificationButton extends StatelessWidget {
  const _NotificationButton({required this.onTap, this.unreadCount = 0});

  final VoidCallback onTap;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      offset: const Offset(0, 4),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: _UnreadCountBadge(count: unreadCount),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Red/white unread-count pill on the notification bell. Caps the printed
/// number at "9+" rather than growing unbounded — the badge is a glance
/// signal, not an exact count display.
class _UnreadCountBadge extends StatelessWidget {
  const _UnreadCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: AppColors.surface, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.danger.withValues(alpha: 0.35),
            offset: const Offset(0, 2),
            blurRadius: 6,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        count > 9 ? '9+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
