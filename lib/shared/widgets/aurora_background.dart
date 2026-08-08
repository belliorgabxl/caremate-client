import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Soft, blurred jewel-tone blobs anchored behind a screen's hero region.
/// This exists to be sampled by [AppCard]'s `glass` variant via
/// BackdropFilter — it is a color source for frosted glass, not standalone
/// decoration, so keep it behind glass cards rather than bare content.
class AuroraBackground extends StatelessWidget {
  const AuroraBackground({super.key, this.height = 460});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
          child: Stack(
            children: [
              Positioned(
                top: -70,
                left: -90,
                child: _blob(AppColors.primary, 260),
              ),
              Positioned(
                top: -30,
                right: -100,
                child: _blob(AppColors.serviceMedication, 230),
              ),
              Positioned(
                top: height * 0.35,
                left: -70,
                child: _blob(AppColors.serviceHomeCare, 220),
              ),
              Positioned(
                top: height * 0.3,
                right: -80,
                child: _blob(AppColors.serviceTransport, 200),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.5),
      ),
    );
  }
}
