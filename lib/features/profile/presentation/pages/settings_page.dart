import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class _SecurityItem {
  _SecurityItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.enabled,
  });

  final String title;
  final String description;
  final IconData icon;
  bool enabled;
}

class _LoginHistoryItem {
  const _LoginHistoryItem({
    required this.device,
    required this.location,
    required this.time,
    this.current = false,
  });

  final String device;
  final String location;
  final String time;
  final bool current;
}

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _items = [
    _SecurityItem(
      title: 'แจ้งเตือนการเข้าสู่ระบบ',
      description: 'แจ้งเตือนเมื่อมีการเข้าสู่ระบบจากอุปกรณ์ใหม่',
      icon: Icons.notifications_active_outlined,
      enabled: true,
    ),
    _SecurityItem(
      title: 'ล็อกด้วยไบโอเมตริก',
      description: 'ใช้ Face ID หรือลายนิ้วมือก่อนเข้าหน้าสำคัญ',
      icon: Icons.fingerprint_rounded,
      enabled: false,
    ),
    _SecurityItem(
      title: 'ยืนยันตัวตนก่อนชำระเงิน',
      description: 'ยืนยันตัวตนก่อนชำระเงินหรือทำรายการสำคัญ',
      icon: Icons.verified_user_outlined,
      enabled: true,
    ),
  ];

  static const _loginHistory = [
    _LoginHistoryItem(
      device: 'Android • CareMate App',
      location: 'กรุงเทพมหานคร',
      time: 'วันนี้ 12:34',
      current: true,
    ),
    _LoginHistoryItem(
      device: 'Chrome on Windows',
      location: 'กรุงเทพมหานคร',
      time: 'เมื่อวาน 21:45',
    ),
  ];

  int get _activeCount => _items.where((item) => item.enabled).length;

  Future<void> _confirmSignOutAllDevices() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ออกจากระบบทุกอุปกรณ์'),
        content: const Text(
          'คุณต้องการออกจากระบบในทุกอุปกรณ์ใช่หรือไม่? คุณจะต้องเข้าสู่ระบบใหม่อีกครั้ง',
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

    if (confirmed == true) {
      await ref.read(authControllerProvider).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('ตั้งค่าความปลอดภัย'),
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
              AppCard(
                glass: true,
                padding: const EdgeInsets.all(22),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ระดับความปลอดภัย',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$_activeCount/${_items.length}',
                            style: textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'เปิดใช้งานมาตรการความปลอดภัยแล้ว $_activeCount รายการ',
                            style: textTheme.bodySmall?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const CircleIconAvatar(
                      icon: Icons.shield_rounded,
                      color: AppColors.primary,
                      radius: 26,
                      iconSize: 28,
                      filled: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'การป้องกันบัญชี',
                icon: Icons.security_rounded,
              ),
              const SizedBox(height: 12),
              ..._items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AppCard(
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: AppColors.primaryLight,
                          child: Icon(item.icon, color: AppColors.primary),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.title, style: textTheme.titleSmall),
                              const SizedBox(height: 3),
                              Text(
                                item.description,
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: item.enabled,
                          onChanged: (v) => setState(() => item.enabled = v),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'รหัสผ่านบัญชี',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'เปลี่ยนรหัสผ่านหรือรีเซ็ตการเข้าสู่ระบบ',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('ฟีเจอร์นี้อยู่ระหว่างการพัฒนา'),
                          ),
                        );
                      },
                      child: const Text('เปลี่ยนรหัสผ่าน'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'ประวัติการเข้าสู่ระบบ',
                icon: Icons.history_rounded,
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: EdgeInsets.zero,
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      for (var i = 0; i < _loginHistory.length; i++) ...[
                        if (i > 0) const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.devices_rounded),
                          title: Text(
                            _loginHistory[i].device,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${_loginHistory[i].location} • ${_loginHistory[i].time}',
                          ),
                          trailing: _loginHistory[i].current
                              ? Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.successBg,
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.pill,
                                    ),
                                  ),
                                  child: const Text(
                                    'ปัจจุบัน',
                                    style: TextStyle(
                                      color: AppColors.success,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: AppColors.danger.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ออกจากระบบทุกอุปกรณ์',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ใช้เมื่อต้องการออกจากระบบทุกอุปกรณ์ หากสงสัยว่าบัญชีถูกใช้งานโดยคนอื่น',
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.danger,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.danger,
                        ),
                        onPressed: _confirmSignOutAllDevices,
                        child: const Text('ออกจากระบบทุกอุปกรณ์'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
