class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    required this.displayName,
    required this.avatarUrl,
    required this.isActive,
  });

  final String id;
  final String phone;
  final String displayName;
  final String avatarUrl;
  final bool isActive;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        displayName: json['name'] as String? ?? '',
        avatarUrl: json['avatarUrl'] as String? ?? '',
        isActive: json['isActive'] as bool? ?? true,
      );

  AppUser copyWith({
    String? id,
    String? phone,
    String? displayName,
    String? avatarUrl,
    bool? isActive,
  }) {
    return AppUser(
      id: id ?? this.id,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}
