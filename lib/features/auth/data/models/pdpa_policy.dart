class PdpaSection {
  const PdpaSection({required this.title, required this.body});

  final String title;
  final String body;

  factory PdpaSection.fromJson(Map<String, dynamic> json) {
    return PdpaSection(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }
}

/// Proposed shape for `GET /legal/pdpa` — **not yet implemented on the
/// backend** (see CLAUDE.md). Lets legal copy change without an app release;
/// `version` is echoed back on `POST /authentication/register` so the
/// consent record is tied to the exact text the user agreed to.
class PdpaPolicy {
  const PdpaPolicy({required this.version, required this.title, required this.sections});

  final String version;
  final String title;
  final List<PdpaSection> sections;

  factory PdpaPolicy.fromJson(Map<String, dynamic> json) {
    return PdpaPolicy(
      version: json['version'] as String? ?? '',
      title: json['title'] as String? ?? '',
      sections: (json['sections'] as List<dynamic>? ?? [])
          .map((e) => PdpaSection.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
