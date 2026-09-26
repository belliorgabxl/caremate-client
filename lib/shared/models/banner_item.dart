import 'booking.dart' show pickField;

/// Maps `GET /banners` rows. Only `id`/`title` are guaranteed non-null by
/// the backend contract — everything else is read defensively via
/// [pickField] since the backend mixes snake_case/camelCase per-field, the
/// same established inconsistency as the rest of this codebase's endpoints.
class BannerItem {
  const BannerItem({
    required this.id,
    required this.title,
    this.body,
    this.imageUrl,
    this.linkUrl,
    this.isActive = true,
    this.sortOrder = 0,
    this.startsAt,
    this.endsAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? body;
  final String? imageUrl;
  final String? linkUrl;
  final bool isActive;
  final int sortOrder;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? createdAt;

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    final startsAtRaw = pickField(json, ['starts_at', 'startsAt']) as String?;
    final endsAtRaw = pickField(json, ['ends_at', 'endsAt']) as String?;
    final createdAtRaw =
        pickField(json, ['created_at', 'createdAt']) as String?;

    return BannerItem(
      id: json['id'] as String? ?? '',
      title: (pickField(json, ['title', 'Title']) as String?) ?? '',
      body: pickField(json, ['body', 'Body']) as String?,
      imageUrl: pickField(json, ['image_url', 'imageUrl']) as String?,
      linkUrl: pickField(json, ['link_url', 'linkUrl']) as String?,
      isActive: (pickField(json, ['is_active', 'isActive']) as bool?) ?? true,
      sortOrder:
          (pickField(json, ['sort_order', 'sortOrder']) as num?)?.toInt() ?? 0,
      startsAt: startsAtRaw == null ? null : DateTime.tryParse(startsAtRaw),
      endsAt: endsAtRaw == null ? null : DateTime.tryParse(endsAtRaw),
      createdAt: createdAtRaw == null ? null : DateTime.tryParse(createdAtRaw),
    );
  }
}
