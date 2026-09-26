import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../shared/utils/confirm_dialogs.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/back_circle_button.dart';
import '../../../../shared/widgets/section_header.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  Future<void> _confirmSignOut() async {
    if (!await confirmLogout(context)) return;
    await ref.read(authControllerProvider).logout();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
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
                title: 'บัญชีของฉัน',
                icon: Icons.manage_accounts_rounded,
              ),
              const SizedBox(height: 12),
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
                          Icons.logout_rounded,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'ออกจากระบบ',
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ออกจากระบบบัญชีนี้บนอุปกรณ์นี้ ต้องเข้าสู่ระบบใหม่ในครั้งถัดไป',
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
                        onPressed: _confirmSignOut,
                        child: const Text('ออกจากระบบ'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Painted after the ListView so it stays on top for hit-testing.
          Positioned(
            top: MediaQuery.paddingOf(context).top + 8,
            left: 20,
            child: BackCircleButton(
              onTap: () => context.popBack(AppRoutes.profile),
            ),
          ),
        ],
      ),
    );
  }
}
