import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Full-page loading state: a car bouncing gently over a continuously
/// scrolling dashed road line, in the app's own brand color — a nod to
/// CareMate's transport/pickup bookings instead of a generic spinner.
class AppLoadingIndicator extends StatefulWidget {
  const AppLoadingIndicator({super.key, this.width = 168, this.height = 64});

  final double width;
  final double height;

  @override
  State<AppLoadingIndicator> createState() => _AppLoadingIndicatorState();
}

class _AppLoadingIndicatorState extends State<AppLoadingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(widget.height / 2),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.32),
              offset: const Offset(0, 4),
              blurRadius: 14,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.height / 2),
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              // Two bounces (small suspension dips) per road-dash cycle
              // reads as rolling over bumps in sync with the road beneath.
              final bounce =
                  math.sin(_controller.value * 2 * math.pi * 2).abs() * 3;
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size.infinite,
                    painter: _RoadPainter(progress: _controller.value),
                  ),
                  Transform.translate(
                    offset: Offset(0, -8 - bounce),
                    child: const Icon(
                      Icons.directions_car_rounded,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed road line scrolling continuously leftward beneath the car
/// — the car stays put while the road moves, same illusion as a treadmill.
class _RoadPainter extends CustomPainter {
  const _RoadPainter({required this.progress});

  final double progress;

  static const _dashWidth = 10.0;
  static const _gapWidth = 8.0;
  static const _period = _dashWidth + _gapWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final y = size.height * 0.76;
    final shift = progress * _period;

    var x = -_period - shift % _period;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset(x + _dashWidth, y), paint);
      x += _period;
    }
  }

  @override
  bool shouldRepaint(covariant _RoadPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
