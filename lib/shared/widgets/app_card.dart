import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_radius.dart';
import '../../core/constants/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.color = AppColors.surface,
    this.borderColor = AppColors.border,
    this.radius = AppRadius.md,
    this.elevated = false,
    this.glass = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;

  /// Hero-level surfaces (primary summaries, stats, CTAs) drop the border
  /// and carry DESIGN.md's two-layer "Card lift" shadow instead — reserve
  /// this for the one or two cards on a screen that should read as the
  /// peak; grid/list-row cards stay on the default bordered Soft-lift so
  /// the hierarchy is legible at a glance, not uniform.
  final bool elevated;

  /// Frosted-glass treatment for cards that sit over an [AuroraBackground]
  /// blob: real backdrop blur + translucent fill + light hairline, so the
  /// blur is revealing the color underneath, not decoration on its own.
  /// Implies [elevated]; only use where an aurora blob is actually behind
  /// the card, otherwise it just frosts the plain background.
  final bool glass;

  static const _liftShadow = [
    BoxShadow(color: Color(0x1A10233F), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0F10233F), offset: Offset(0, 8), blurRadius: 24),
  ];

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);

    final decoratedChild = glass
        ? ClipRRect(
            borderRadius: borderRadius,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: padding,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.55),
                  borderRadius: borderRadius,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.65),
                    width: 1.2,
                  ),
                  boxShadow: _liftShadow,
                ),
                child: child,
              ),
            ),
          )
        : Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color,
              borderRadius: borderRadius,
              border: elevated ? null : Border.all(color: borderColor),
              boxShadow: elevated
                  ? _liftShadow
                  : const [
                      BoxShadow(
                        color: Color(0x0D10233F),
                        offset: Offset(0, 2),
                        blurRadius: 8,
                      ),
                    ],
            ),
            child: child,
          );

    if (onTap == null) return decoratedChild;

    return Material(
      color: Colors.transparent,
      borderRadius: borderRadius,
      child: InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        child: decoratedChild,
      ),
    );
  }
}
