import 'package:flutter/material.dart';

/// Icon badge with real depth: a soft colored shadow (own hue, real offset
/// + blur — never a zero-offset halo) and a fine ring at low alpha of the
/// same hue, so a tint-only circle never ships as the finished state.
class CircleIconAvatar extends StatelessWidget {
  const CircleIconAvatar({
    super.key,
    required this.icon,
    required this.color,
    this.radius = 24,
    this.filled = false,
    this.iconSize,
  });

  final IconData icon;
  final Color color;
  final double radius;
  final bool filled;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final diameter = radius * 2;

    return Container(
      width: diameter,
      height: diameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? color : color.withValues(alpha: 0.12),
        border: Border.all(
          color: color.withValues(alpha: filled ? 0.0 : 0.18),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: filled ? 0.30 : 0.16),
            offset: Offset(0, radius * 0.16),
            blurRadius: radius * 0.55,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: filled ? Colors.white : color,
        size: iconSize ?? radius * 0.9,
      ),
    );
  }
}
