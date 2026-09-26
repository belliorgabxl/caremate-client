import 'booking.dart';

/// `GET /public/tracking/:token` response — the app's one fully public,
/// no-auth endpoint (SOS/share-location contract, 2026-08). Parsed
/// defensively with [pickField] the same as every other booking endpoint
/// even though the spec states camelCase, since this backend's field
/// casing has been confirmed per-endpoint-inconsistent everywhere else.
/// A 404 (invalid or expired token, indistinguishable) is not represented
/// here — [BookingRepository.getPublicTracking] lets that surface as a
/// normal [ApiException] for the caller to branch on.
class PublicTracking {
  const PublicTracking({
    required this.bookingStatus,
    this.partnerName,
    this.partnerLat,
    this.partnerLng,
    this.pickupAddress,
    this.destinationAddress,
    this.expiresAt,
  });

  final BookingStatus bookingStatus;
  final String? partnerName;
  final double? partnerLat;
  final double? partnerLng;
  final String? pickupAddress;
  final String? destinationAddress;
  final DateTime? expiresAt;

  factory PublicTracking.fromJson(Map<String, dynamic> json) {
    final expiresRaw =
        pickField(json, const ['expiresAt', 'expires_at']) as String?;

    return PublicTracking(
      bookingStatus: BookingStatusX.fromApi(
        pickField(json, const ['bookingStatus', 'booking_status', 'status'])
            as String?,
      ),
      partnerName:
          pickField(json, const ['partnerName', 'partner_name']) as String?,
      partnerLat: (pickField(json, const ['partnerLat', 'partner_lat']) as num?)
          ?.toDouble(),
      partnerLng: (pickField(json, const ['partnerLng', 'partner_lng']) as num?)
          ?.toDouble(),
      pickupAddress:
          pickField(json, const ['pickupAddress', 'pickup_address']) as String?,
      destinationAddress:
          pickField(json, const ['destinationAddress', 'destination_address'])
              as String?,
      expiresAt: expiresRaw == null ? null : DateTime.tryParse(expiresRaw),
    );
  }
}
