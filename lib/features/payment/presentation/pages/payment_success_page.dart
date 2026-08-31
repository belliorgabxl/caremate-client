import 'package:flutter/material.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/router/nav_direction.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../shared/models/booking.dart';
import '../../../../shared/widgets/aurora_background.dart';
import '../../../../shared/widgets/circle_icon_avatar.dart';
import '../../../../shared/widgets/primary_button.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key, required this.booking});

  final Booking booking;

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
            child: AuroraBackground(height: 420),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  const CircleIconAvatar(
                    icon: Icons.check_circle_rounded,
                    color: AppColors.success,
                    radius: 48,
                    filled: true,
                    iconSize: 52,
                  ),
                  const SizedBox(height: 20),
                  Text('ชำระเงินสำเร็จ', style: textTheme.headlineMedium),
                  const SizedBox(height: 10),
                  Text(
                    'ระบบได้บันทึกรายการชำระเงินเรียบร้อยแล้ว',
                    textAlign: TextAlign.center,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  PrimaryButton(
                    label: 'ติดตามสถานะการจอง',
                    icon: Icons.track_changes_rounded,
                    onPressed: () => context.goForward(
                      AppRoutes.bookingStatusPath(booking.id),
                      extra: booking,
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.goBack(AppRoutes.home),
                      child: const Text('กลับหน้าหลัก'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
