import 'package:flutter/material.dart';

import 'app_card.dart';

/// Compact stat tile — ported from the Partner app's `CmStatTile`
/// (`core_ui`): left-aligned big value over an uppercase micro-label, on
/// this app's own [AppCard] surface (elevated, so it carries the same real
/// lift shadow every other "peak" card on this app uses) rather than
/// Partner's own hand-rolled glass container. Distinct from the
/// icon-centered stat columns Home composes inline inside its hero card —
/// this is the freestanding, one-tile-per-metric shape for places that
/// want several stats side by side without a shared hero.
class StatTile extends StatelessWidget {
  const StatTile({super.key, required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AppCard(
      elevated: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(letterSpacing: -0.2),
          ),
          const SizedBox(height: 2),
          Text(
            label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(letterSpacing: 1.0),
          ),
        ],
      ),
    );
  }
}
