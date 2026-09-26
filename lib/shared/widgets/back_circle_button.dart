import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Replaces the plain white [AppBar] most pages used to carry their back
/// button on — a small floating circle over whatever hero/wash sits behind
/// it instead of a flat bar. Pages place this themselves (`Positioned` at
/// the top-left, below the status bar) since layouts vary.
class BackCircleButton extends StatelessWidget {
  const BackCircleButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: AppColors.textPrimary.withValues(alpha: 0.2),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 40,
          height: 40,
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primary,
            size: 20,
          ),
        ),
      ),
    );
  }
}
