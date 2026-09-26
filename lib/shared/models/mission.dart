import 'booking.dart';

/// `GET /bookings/:bookingId/mission` response — `mission`/`partner` are
/// null until the booking reaches `MATCHED` / `IN_PROGRESS`.
class BookingMissionDetail {
  const BookingMissionDetail({
    required this.booking,
    this.mission,
    this.partner,
  });

  final Booking booking;
  final Mission? mission;
  final Partner? partner;
}

class Partner {
  const Partner({
    required this.id,
    required this.name,
    required this.phone,
    this.ratingAvg,
    this.currentLat,
    this.currentLng,
    this.verified = false,
  });

  final String id;
  final String name;
  final String phone;
  final double? ratingAvg;
  final double? currentLat;
  final double? currentLng;

  /// The backend doesn't send a dedicated `verified` field — it embeds the
  /// full partner row, so `status == "active"` (the same value gating
  /// partner login server-side, see care-mate-backend's `domain.CanLogin`)
  /// is the real signal a fully-vetted partner has been matched. Defaults to
  /// false if `status` is absent (absence of the badge is the neutral
  /// state, never a "not verified" negative signal).
  final bool verified;

  factory Partner.fromJson(Map<String, dynamic> json) {
    final status = pickField(json, const ['status', 'Status']) as String?;
    return Partner(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '-',
      phone: json['phone'] as String? ?? '',
      ratingAvg: (json['rating_avg'] as num?)?.toDouble(),
      currentLat: (json['current_lat'] as num?)?.toDouble(),
      currentLng: (json['current_lng'] as num?)?.toDouble(),
      verified: status == 'active',
    );
  }
}

class MissionCheckpoint {
  const MissionCheckpoint({
    required this.id,
    required this.step,
    required this.labelTh,
    required this.labelEn,
    required this.notes,
    this.completedAt,
    this.photoUrl,
  });

  final String id;
  final int step;
  final String labelTh;
  final String labelEn;
  final String notes;
  final DateTime? completedAt;

  /// Photo the partner attached at this checkpoint. Null/absent until they
  /// upload one for this step — not every checkpoint gets a photo.
  final String? photoUrl;

  bool get isDone => completedAt != null;

  factory MissionCheckpoint.fromJson(Map<String, dynamic> json) {
    final completedRaw = json['completed_at'] as String?;
    final photoUrl = json['photo_url'] as String?;

    return MissionCheckpoint(
      id: json['id'] as String? ?? '',
      step: (json['step'] as num?)?.toInt() ?? 0,
      labelTh: json['label_th'] as String? ?? '',
      labelEn: json['label_en'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
      completedAt: completedRaw == null
          ? null
          : DateTime.tryParse(completedRaw),
      photoUrl: (photoUrl == null || photoUrl.isEmpty) ? null : photoUrl,
    );
  }
}

class Mission {
  const Mission({
    required this.id,
    required this.bookingId,
    required this.partnerId,
    required this.status,
    required this.checkpoints,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String bookingId;
  final String partnerId;
  final String status;
  final List<MissionCheckpoint> checkpoints;
  final DateTime? startedAt;
  final DateTime? completedAt;

  factory Mission.fromJson(Map<String, dynamic> json) {
    final startedRaw = json['started_at'] as String?;
    final completedRaw = json['completed_at'] as String?;
    final checkpointsJson = json['checkpoints'] as List<dynamic>? ?? const [];

    return Mission(
      id: json['id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      partnerId: json['partner_id'] as String? ?? '',
      status: json['status'] as String? ?? '',
      checkpoints: [
        for (final c in checkpointsJson)
          MissionCheckpoint.fromJson(c as Map<String, dynamic>),
      ],
      startedAt: startedRaw == null ? null : DateTime.tryParse(startedRaw),
      completedAt: completedRaw == null
          ? null
          : DateTime.tryParse(completedRaw),
    );
  }
}
