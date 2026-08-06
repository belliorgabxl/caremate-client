import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';

class HeroHeaderCard extends StatelessWidget {
  const HeroHeaderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.leadingIcon,
    this.badgeText,
    this.badgeIcon = Icons.verified_rounded,
    this.actions,
    this.footer,
  });

  final String title;
  final String subtitle;
  final IconData leadingIcon;
  final String? badgeText;
  final IconData badgeIcon;
  final Widget? actions;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.primaryDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white.withValues(alpha: 0.16),
                child: Icon(leadingIcon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, color: Colors.white, size: 16),
                      const SizedBox(width: 5),
                      Text(
                        badgeText!,
                        style: textTheme.labelMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              height: 1.4,
            ),
          ),
          if (actions != null) ...[const SizedBox(height: 20), actions!],
          if (footer != null) ...[const SizedBox(height: 18), footer!],
        ],
      ),
    );
  }
}
