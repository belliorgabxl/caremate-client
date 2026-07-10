import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CareMate'),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Mock: ยังไม่มี Notification จริง'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Badge(
              label: Text('3'),
              child: Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
        children: [
          _HeroSection(
            name: user?.displayName ?? 'ผู้ใช้งาน',
            phone: user?.phone ?? '-',
          ),
          const SizedBox(height: 18),
          const _QuickStatsSection(),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'บริการด่วน',
            subtitle: 'เลือกสิ่งที่ต้องการให้ CareMate ช่วยดูแล',
            actionText: 'ทั้งหมด',
            onActionTap: () => context.go(AppRoutes.booking),
          ),
          const SizedBox(height: 12),
          const _QuickActionsGrid(),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'นัดหมายล่าสุด',
            subtitle: 'รายการจองที่กำลังจะมาถึง',
            actionText: 'ดูรายการ',
            onActionTap: () => context.go(AppRoutes.booking),
          ),
          const SizedBox(height: 12),
          const _UpcomingBookingCard(),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'สมาชิกที่ดูแล',
            subtitle: 'เลือกสมาชิกเพื่อจองบริการอย่างรวดเร็ว',
            actionText: 'จัดการ',
            onActionTap: () => context.go(AppRoutes.members),
          ),
          const SizedBox(height: 12),
          const _FamilyPreview(),
          const SizedBox(height: 24),
          _SectionTitle(
            title: 'การชำระเงิน',
            subtitle: 'สรุปรายการชำระเงินล่าสุด',
            actionText: 'ดูเพิ่ม',
            onActionTap: () => context.go(AppRoutes.payment),
          ),
          const SizedBox(height: 12),
          const _PaymentSummaryCard(),
          const SizedBox(height: 24),
          const _CareTipsCard(),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.name,
    required this.phone,
  });

  final String name;
  final String phone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2CB7A0),
            Color(0xFF168B78),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.health_and_safety_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Mock Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'สวัสดีครับ, $name',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'เบอร์โทร: $phone',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'วันนี้ต้องการให้ CareMate ช่วยดูแลอะไรครับ?',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.90),
              fontSize: 15,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
          Row(
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
                  icon: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickStatsSection extends StatelessWidget {
  const _QuickStatsSection();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatCard(
            title: '4',
            subtitle: 'สมาชิก',
            icon: Icons.people_alt_rounded,
            color: AppColors.primary,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: '2',
            subtitle: 'นัดหมาย',
            icon: Icons.calendar_month_rounded,
            color: Color(0xFF5B8DEF),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            title: '1',
            subtitle: 'รอชำระ',
            icon: Icons.receipt_long_rounded,
            color: Color(0xFFFF9F43),
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
        color: AppColors.primary,
        route: AppRoutes.booking,
      ),
      _HomeAction(
        icon: Icons.volunteer_activism_rounded,
        title: 'ดูแลรายชั่วโมง',
        subtitle: 'ที่บ้าน / คอนโด',
        color: const Color(0xFF5B8DEF),
        route: AppRoutes.booking,
      ),
      _HomeAction(
        icon: Icons.medication_rounded,
        title: 'ซื้อยา',
        subtitle: 'ยาและเวชภัณฑ์',
        color: const Color(0xFFFF9F43),
        route: AppRoutes.booking,
      ),
      _HomeAction(
        icon: Icons.groups_rounded,
        title: 'สมาชิกของฉัน',
        subtitle: 'จัดการครอบครัว',
        color: const Color(0xFFB56EFF),
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

        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => context.go(action.route),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 23,
                    backgroundColor: action.color.withValues(alpha: 0.12),
                    child: Icon(
                      action.icon,
                      color: action.color,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    action.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    action.subtitle,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _UpcomingBookingCard extends StatelessWidget {
  const _UpcomingBookingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.local_taxi_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'รับ-ส่งพบแพทย์',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'ให้พ่อ • พรุ่งนี้ 09:30 น.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF5B8DEF).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'MATCHED',
                  style: TextStyle(
                    color: Color(0xFF5B8DEF),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: const [
                Icon(
                  Icons.location_on_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'คอนโด CareMate Residence → โรงพยาบาลสมิติเวช สุขุมวิท',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Mock: ดูรายละเอียด booking'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('ดูรายละเอียด'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
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
}

class _FamilyPreview extends StatelessWidget {
  const _FamilyPreview();

  @override
  Widget build(BuildContext context) {
    final members = [
      const _FamilyMember(
        name: 'Gabel',
        relation: 'ตัวเอง',
        icon: Icons.person_rounded,
        color: AppColors.primary,
      ),
      const _FamilyMember(
        name: 'พ่อ',
        relation: 'บิดา',
        icon: Icons.elderly_rounded,
        color: Color(0xFF5B8DEF),
      ),
      const _FamilyMember(
        name: 'แม่',
        relation: 'มารดา',
        icon: Icons.favorite_rounded,
        color: Color(0xFFFF9F43),
      ),
      const _FamilyMember(
        name: 'มิน',
        relation: 'น้องสาว',
        icon: Icons.face_3_rounded,
        color: Color(0xFFB56EFF),
      ),
    ];

    return SizedBox(
      height: 136, // เพิ่มจาก 116 เป็น 136 เพื่อกัน overflow
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: members.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final member = members[index];

          return GestureDetector(
            onTap: () => context.go(AppRoutes.members),
            child: Container(
              width: 104,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: member.color.withValues(alpha: 0.12),
                    child: Icon(
                      member.icon,
                      color: member.color,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.relation,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
}

class _PaymentSummaryCard extends StatelessWidget {
  const _PaymentSummaryCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: const Color(0xFFFF9F43).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.payment_rounded,
              color: Color(0xFFFF9F43),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'รอชำระ 1 รายการ',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'ยอดรวมโดยประมาณ ฿685',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: AppColors.primary.withValues(alpha: 0.08),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          CircleAvatar(
            backgroundColor: AppColors.primary,
            child: Icon(
              Icons.tips_and_updates_rounded,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Care Tip วันนี้',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'ก่อนพาผู้สูงอายุไปโรงพยาบาล ควรเตรียมยาเดิม บัตรประชาชน และประวัติแพ้ยาไว้ให้พร้อม',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onActionTap,
  });

  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onActionTap,
          child: Text(actionText),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
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

class _FamilyMember {
  const _FamilyMember({
    required this.name,
    required this.relation,
    required this.icon,
    required this.color,
  });

  final String name;
  final String relation;
  final IconData icon;
  final Color color;
}