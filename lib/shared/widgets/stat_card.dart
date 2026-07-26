import 'package:flutter/material.dart';

import 'app_card.dart';
import 'circle_icon_avatar.dart';

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          CircleIconAvatar(icon: icon, color: color, radius: 20, iconSize: 22),
          const SizedBox(height: 10),
          Text(title, style: textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(subtitle, style: textTheme.labelMedium),
        ],
      ),
    );
  }
}
