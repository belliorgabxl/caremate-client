import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      ref.read(authControllerProvider).checkSession();
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleIconAvatar(
              icon: Icons.health_and_safety,
              color: AppColors.primary,
              radius: 44,
              filled: true,
              iconSize: 44,
            ),
            const SizedBox(height: 20),
            Text('CareMate', style: textTheme.displayMedium),
            const SizedBox(height: 8),
            Text('Your care, anytime.', style: textTheme.bodyLarge?.copyWith(
              color: AppColors.textSecondary,
            )),
            const SizedBox(height: 28),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
