import 'package:flutter/material.dart';

class CareService {
  const CareService({
    required this.id,
    required this.slug,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.baseFeePerHour,
    required this.requiresDestination,
    required this.durationMinutes,
    required this.typicalDistanceKm,
  });

  final String id;
  final String slug;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final double baseFeePerHour;
  final bool requiresDestination;
  final int durationMinutes;
  final double typicalDistanceKm;
}
