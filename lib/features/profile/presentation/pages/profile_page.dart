import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          AppCard(
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
                      Text(user?.displayName ?? '-', style: textTheme.headlineSmall),
                      const SizedBox(height: 4),
                      Text(user?.phone ?? '-', style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined),
                  title: const Text('Account information'),
                  subtitle: Text('User ID: ${user?.id ?? '-'}'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.danger),
                  title: Text(
                    'Logout',
                    style: textTheme.bodyLarge?.copyWith(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  onTap: () async {
                    await ref.read(authControllerProvider).logout();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
