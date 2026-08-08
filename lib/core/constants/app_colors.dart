import 'package:flutter/material.dart';

/// "Tidewater" palette — cool mist-white ground, teal→blue brand identity
/// sampled from the real app icon gradient, pinned 2026-08-07 as the
/// direction that supersedes "Aurora Glass". Shares a family (soft washes,
/// warm-tinted depth, pill controls) with the sibling Partner app's warm
/// orange system without copying its hue. See DESIGN.md.
class AppColors {
  // Brand anchor. Neither raw logo-gradient endpoint (#26DAD2 / #04ACCF)
  // clears 4.5:1 under white text, so `primary` is a deepened point on the
  // same hue — the true gradient lives in accentGradientStart/End for
  // decorative (non-text-bearing) surfaces only. Feeds
  // ColorScheme.fromSeed in AppTheme and carries global chrome (nav, focus,
  // default CTAs).
  static const primary = Color(0xFF0E7A94);
  static const primaryDark = Color(0xFF0A5E73);
  static const primaryLight = Color(0xFFE3F6F5);
  static const onPrimary = Color(0xFFFFFFFF);
  static const onPrimaryContainer = Color(0xFF0A5E73);

  // Decorative-only gradient pair, sampled directly from app_icon.png —
  // never place text directly on these without a scrim.
  static const accentGradientStart = Color(0xFF22D3C6);
  static const accentGradientEnd = Color(0xFF0EA5C4);

  // Neutrals / surfaces — cool mist-white ground (own identity vs. the
  // Partner app's warm cream) so the teal/blue accent reads vivid against
  // it rather than blending in.
  static const background = Color(0xFFF3FAFA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFEAF6F5);
  static const border = Color(0xFFD7EBEA);
  static const textPrimary = Color(0xFF0F2A2E);
  static const textSecondary = Color(0xFF4E6B6E);
  static const textTertiary = Color(0xFF86A0A2);
  static const divider = Color(0xFFD7EBEA);

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
