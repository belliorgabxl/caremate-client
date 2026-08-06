import 'package:flutter/material.dart';

/// "Aurora Glass" palette — cool-white ground, jewel-tone brand colors at
/// full weight (not just categorization tints), pinned 2026-08-05 as the
/// direction that supersedes "Premium Clinic Companion"'s One Blue Rule.
/// See PRODUCT.md Brand Commitments.
class AppColors {
  // Brand anchor — Sapphire. Feeds ColorScheme.fromSeed in AppTheme and
  // carries global chrome (nav, focus, default CTAs).
  static const primary = Color(0xFF1668E3);
  static const primaryDark = Color(0xFF0D4EA8);
  static const primaryLight = Color(0xFFE6F0FE);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF0A3D91);

  // Neutrals / surfaces — cool-white ground (kept, not warmed) so the
  // jewel colors read vivid against it rather than blending into a tint.
  static const background = Color(0xFFF5F9FF);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFEFF5FC);
  static const border = Color(0xFFDCE7F5);
  static const textPrimary = Color(0xFF10233F);
  static const textSecondary = Color(0xFF54677E);
  static const textTertiary = Color(0xFF8FA0B5);
  static const divider = Color(0xFFDCE7F5);

  // Status / semantic
  static const success = Color(0xFF12A150);
  static const successBg = Color(0xFFE3F8EC);
  static const danger = Color(0xFFE0342C);
  static const dangerBg = Color(0xFFFCE8E7);
  static const warning = Color(0xFFE08A00);
  static const warningBg = Color(0xFFFFF3DC);
  static const info = Color(0xFF0B84C4);
  static const infoBg = Color(0xFFE1F4FC);

  // Jewel palette — four full-brand-weight hues, one per service category.
  // These now carry real chrome (hero glass tints, matching CTAs, aurora
  // blobs), not just small icon tints — the "One Blue Rule" no longer
  // applies. Kept as the same four category roles used app-wide so no
  // call site needs renaming.
  static const serviceTransport = Color(0xFFFF6F5C); // Coral
  static const serviceHomeCare = Color(0xFF0EA66B); // Emerald
  static const serviceMedication = Color(0xFF7C3AED); // Amethyst
  static const serviceErrand = Color(0xFFE8478D); // Rose

  static const List<Color> serviceColors = [
    serviceTransport,
    serviceHomeCare,
    serviceMedication,
    serviceErrand,
  ];

  // Status badge tokens
  static const badgeDefault = Color(0xFFB4740A);
  static const badgeDefaultBg = Color(0xFFFFF3DC);
}
