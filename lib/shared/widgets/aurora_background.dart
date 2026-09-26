import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// "Tide wash" background — vertical mist-white gradient with 2 soft radial
/// teal/blue blobs fading to transparent. Same family instinct as the
/// sibling Partner app's `CmBackground` (soft wash behind hero content),
/// re-tinted to this app's own teal→blue identity. Deliberately no
/// `BackdropFilter` blur and deliberately few stacked alpha layers — an
/// earlier version piled a dot-grid texture and a second fade gradient on
/// top of the blobs, and the combination of many low-alpha layers over a
/// near-white base produced visible gradient banding on-device. Purely
/// decorative; place behind foreground content in a [Stack] (e.g. behind a
/// frosted-glass hero card). See DESIGN.md.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, this.height = 280});

  final double height;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(color: AppColors.background),
              ),
              _blob(
                top: -height * 0.35,
                left: -height * 0.2,
                size: height * 1.05,
                color: AppColors.accentGradientStart,
                alpha: 0.26,
              ),
              _blob(
                top: -height * 0.2,
                right: -height * 0.35,
                size: height * 0.9,
                color: AppColors.accentGradientEnd,
                alpha: 0.20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob({
    double? top,
    double? left,
    double? right,
    double? bottom,
    required double size,
    required Color color,
    required double alpha,
  }) {
    return Positioned(
      top: top,
      left: left,
      right: right,
      bottom: bottom,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withValues(alpha: alpha),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
