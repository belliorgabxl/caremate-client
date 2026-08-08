import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/models/user_profile.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/profile_repository.dart';

class _MenuItem {
  const _MenuItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String route;
}

const _menuItems = [
  _MenuItem(
    icon: Icons.person_outline_rounded,
    color: AppColors.primary,
    title: 'ข้อมูลส่วนตัว',
    subtitle: 'ชื่อ อีเมล วันเกิด และเพศ',
    route: AppRoutes.profilePersonalInformation,
  ),
  _MenuItem(
    icon: Icons.medical_information_outlined,
    color: AppColors.serviceMedication,
    title: 'ข้อมูลสุขภาพ',
    subtitle: 'ผู้ติดต่อฉุกเฉิน กรุ๊ปเลือด และประวัติการแพ้',
    route: AppRoutes.profileHealthInformation,
  ),
  _MenuItem(
    icon: Icons.location_on_outlined,
    color: AppColors.serviceTransport,
    title: 'ที่อยู่ของฉัน',
    subtitle: 'จัดการที่อยู่หลักสำหรับการจองบริการ',
    route: AppRoutes.profileAddresses,
  ),
  _MenuItem(
    icon: Icons.diversity_3_outlined,
    color: AppColors.serviceHomeCare,
    title: 'สมาชิกที่ดูแล',
    subtitle: 'จัดการรายชื่อผู้รับบริการ',
    route: AppRoutes.members,
  ),
  _MenuItem(
    icon: Icons.receipt_long_outlined,
    color: AppColors.serviceErrand,
    title: 'ประวัติการจอง',
    subtitle: 'ดูรายการจองทั้งหมดของคุณ',
    route: AppRoutes.bookingHistory,
  ),
  _MenuItem(
    icon: Icons.payment_outlined,
    color: AppColors.info,
    title: 'การชำระเงิน',
    subtitle: 'ตรวจสอบสถานะการชำระเงินล่าสุด',
    route: AppRoutes.payment,
  ),
  _MenuItem(
    icon: Icons.settings_outlined,
    color: AppColors.textSecondary,
    title: 'ตั้งค่าความปลอดภัย',
    subtitle: 'จัดการความปลอดภัยของบัญชี',
    route: AppRoutes.profileSettings,
  ),
];

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _isLoading = true;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = ref.read(authControllerProvider).user;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    final profile = await ref.read(profileRepositoryProvider).getForUser(user);
    if (!mounted) return;
    setState(() {
      _profile = profile;
      _isLoading = false;
    });
  }

  /// Mirrors `SettingsPage._confirmSignOutAllDevices` so both logout paths ask
  /// the same way — this one used to sign the user out on a single stray tap.
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบ'),
        content: const Text(
          'คุณต้องการออกจากระบบใช่หรือไม่? คุณจะต้องเข้าสู่ระบบใหม่อีกครั้ง',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'ออกจากระบบ',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    await ref.read(authControllerProvider).logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final textTheme = Theme.of(context).textTheme;
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                    children: [
                      AppCard(
                        glass: true,
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            const CircleIconAvatar(
                              icon: Icons.person,
                              color: AppColors.primary,
                              radius: 32,
                              filled: true,
                              iconSize: 34,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user?.displayName ?? '-',
                                    style: textTheme.headlineSmall,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    user?.phone ?? '-',
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SectionHeader(
                        title: 'ข้อมูลบัญชี',
                        icon: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: Column(
                          children: [
                            _InfoRow(
                              label: 'อีเมล',
                              value: profile?.email.isNotEmpty == true
                                  ? profile!.email
                                  : 'ยังไม่ระบุ',
                            ),
                            const Divider(height: 1),
                            _InfoRow(
                              label: 'เบอร์โทร',
                              value: user?.phone ?? '-',
                            ),
                            const Divider(height: 1),
                            _InfoRow(
                              label: 'กรุ๊ปเลือด',
                              value: profile?.bloodType.isNotEmpty == true
                                  ? profile!.bloodType
                                  : 'ยังไม่ระบุ',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text('เมนูของฉัน', style: textTheme.titleLarge),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.infoBg,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              '${_menuItems.length} รายการ',
                              style: textTheme.labelMedium?.copyWith(
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._menuItems.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AppCard(
                            onTap: () => context.go(item.route),
                            child: Row(
                              children: [
                                CircleIconAvatar(
                                  icon: item.icon,
                                  color: item.color,
                                  radius: 24,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.title,
                                        style: textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        item.subtitle,
                                        style: textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.textTertiary,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppCard(
                        padding: EdgeInsets.zero,
                        child: ListTile(
                          leading: const Icon(
                            Icons.logout,
                            color: AppColors.danger,
                          ),
                          title: Text(
                            'Logout',
                            style: textTheme.bodyLarge?.copyWith(
                              color: AppColors.danger,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          onTap: _confirmLogout,
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
