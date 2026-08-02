import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

const _iconsByName = {
  'local_taxi': Icons.local_taxi_rounded,
  'transport': Icons.local_taxi_rounded,
  'volunteer_activism': Icons.volunteer_activism_rounded,
  'home_care': Icons.volunteer_activism_rounded,
  'medication': Icons.medication_rounded,
  'accessible_forward': Icons.accessible_forward_rounded,
  'errand': Icons.accessible_forward_rounded,
};

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

  /// Maps a backend `BackendCareService` (`GET /api/service`). The catalog
  /// doesn't carry a subtitle, default duration, or typical distance — those
  /// are presentational defaults, not authoritative (the real total/distance
  /// come back from `POST /api/booking` once a booking is actually created).
  factory CareService.fromJson(Map<String, dynamic> json, {int seq = 0}) {
    final slug = json['slug'] as String? ?? '';

    return CareService(
      id: json['id'] as String? ?? '',
      slug: slug,
      title: json['name_th'] as String? ?? json['name_en'] as String? ?? slug,
      subtitle: json['name_en'] as String? ?? '',
      icon: _iconsByName[json['icon_name'] as String? ?? slug] ?? Icons.medical_services_rounded,
      color: AppColors.serviceColors[seq % AppColors.serviceColors.length],
      baseFeePerHour: (json['base_fee'] as num?)?.toDouble() ?? 0,
      // Per booking-flow.md §3.3: destination fields are required only when
      // the service slug is exactly "transport" — not a loose heuristic.
      requiresDestination: slug == 'transport',
      durationMinutes: 60,
      typicalDistanceKm: 0,
    );
  }
}
