import 'package:flutter/material.dart';

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
    return CircleAvatar(
      radius: radius,
      backgroundColor: filled ? color : color.withValues(alpha: 0.12),
      child: Icon(
        icon,
        color: filled ? Colors.white : color,
        size: iconSize ?? radius * 0.9,
      ),
    );
  }
}
