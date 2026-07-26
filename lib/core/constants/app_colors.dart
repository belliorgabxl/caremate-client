import 'package:flutter/material.dart';

class AppColors {
  // Brand — vivid blue
  static const primary = Color(0xFF2563EB);
  static const primaryDark = Color(0xFF1D4ED8);
  static const primaryLight = Color(0xFFDBEAFE);
  static const onPrimary = Color(0xFFFFFFFF);

  // Neutrals / surfaces
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF1F5F9);
  static const border = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF1E293B);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);
  static const divider = Color(0xFFE2E8F0);

  // Status / semantic
  static const success = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);
  static const danger = Color(0xFFDC2626);
  static const dangerBg = Color(0xFFFEE2E2);
  static const warning = Color(0xFFD97706);
  static const warningBg = Color(0xFFFEF3C7);
  static const info = Color(0xFF0891B2);
  static const infoBg = Color(0xFFCFFAFE);

  // Service-category accents — colorful, fixed set of 4
  static const serviceTransport = Color(0xFFF97316);
  static const serviceHomeCare = Color(0xFF10B981);
  static const serviceMedication = Color(0xFF8B5CF6);
  static const serviceErrand = Color(0xFFEC4899);

  static const List<Color> serviceColors = [
    serviceTransport,
    serviceHomeCare,
    serviceMedication,
    serviceErrand,
  ];

  // Status badge tokens
  static const badgeDefault = Color(0xFFB45309);
  static const badgeDefaultBg = Color(0xFFFEF3C7);
}
