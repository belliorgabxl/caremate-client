import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

/// Circular avatar with an initials fallback — ported from the Partner
/// app's `CmAvatar` (`core_ui`). This app's [CircleIconAvatar] only ever
/// shows an [IconData] glyph; this fills the same role for a person's name
/// (e.g. the greeting avatar on Home) without a photo, using this app's
/// [AppColors.surfaceAlt]/[AppColors.textSecondary] instead of Partner's
/// neutral grey.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    this.name = '',
    this.imageUrl,
    this.size = 40,
  });

  final String name;
  final String? imageUrl;
  final double size;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: AppColors.surfaceAlt,
      foregroundImage: imageUrl == null ? null : NetworkImage(imageUrl!),
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: size * 0.35,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
