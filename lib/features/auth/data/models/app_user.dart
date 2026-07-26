class AppUser {
  const AppUser({
    required this.id,
    required this.phone,
    required this.displayName,
  });

  final String id;
  final String phone;
  final String displayName;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        phone: json['phone'] as String,
        displayName: json['displayName'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'phone': phone,
        'displayName': displayName,
      };
}
