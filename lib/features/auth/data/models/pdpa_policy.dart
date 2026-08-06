DateTime? _parseDate(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// `GET /api/v1/pdpa` (active version) and `GET /api/v1/pdpa/:version`
/// (one specific version) both return this shape. `content` is
/// pre-rendered HTML (`<h2>...</h2><p>...</p>...`) — render it directly,
/// no markdown parsing needed.
class PdpaPolicy {
  const PdpaPolicy({
    required this.id,
    required this.version,
    required this.title,
    required this.content,
    this.summary,
    required this.isActive,
    this.effectiveDate,
    this.updatedAt,
  });

  final String id;
  final String version;
  final String title;
  final String content;
  final String? summary;
  final bool isActive;
  final DateTime? effectiveDate;
  final DateTime? updatedAt;

  factory PdpaPolicy.fromJson(Map<String, dynamic> json) {
    return PdpaPolicy(
      id: json['id'] as String? ?? '',
      version: json['version'] as String? ?? '',
      title: json['title'] as String? ?? '',
      content: json['content'] as String? ?? '',
      summary: json['summary'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      effectiveDate: _parseDate(json['effective_date']),
      updatedAt: _parseDate(json['updated_at']),
    );
  }
}

/// `GET /api/v1/pdpa/versions` list entries — metadata only, no `content`/
/// `id`. Use for a version-history list, not for display of the policy text
/// itself (fetch `GET /pdpa/:version` for that).
class PdpaVersionSummary {
  const PdpaVersionSummary({
    required this.version,
    required this.title,
    this.summary,
    required this.isActive,
    this.effectiveDate,
  });

  final String version;
  final String title;
  final String? summary;
  final bool isActive;
  final DateTime? effectiveDate;

  factory PdpaVersionSummary.fromJson(Map<String, dynamic> json) {
    return PdpaVersionSummary(
      version: json['version'] as String? ?? '',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String?,
      isActive: json['is_active'] as bool? ?? false,
      effectiveDate: _parseDate(json['effective_date']),
    );
  }
}
