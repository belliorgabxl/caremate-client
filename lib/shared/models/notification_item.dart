import 'booking.dart';

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.createdAt,
    this.bookingId,
    this.readAt,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final DateTime createdAt;
  final String? bookingId;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    final createdRaw =
        pickField(json, const ['created_at', 'createdAt']) as String?;
    final readRaw = pickField(json, const ['read_at', 'readAt']) as String?;

    return NotificationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? '',
      bookingId: pickField(json, const ['booking_id', 'bookingId']) as String?,
      createdAt: createdRaw == null
          ? DateTime.now()
          : DateTime.tryParse(createdRaw) ?? DateTime.now(),
      readAt: readRaw == null ? null : DateTime.tryParse(readRaw),
    );
  }
}
