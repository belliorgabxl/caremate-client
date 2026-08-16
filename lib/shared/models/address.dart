class Address {
  const Address({
    required this.addressLine,
    this.latitude,
    this.longitude,
  });

  final String addressLine;
  final double? latitude;
  final double? longitude;

  /// Exact (0, 0) ("Null Island") is treated as unset, not a real fix — no
  /// legitimate CareMate booking is ever actually there. This matters for
  /// rebook-from-history prefills, which fall back to (0, 0) when the
  /// history payload carries an address string but no lat/lng, and must
  /// still force the user through the map picker rather than silently
  /// passing this gate.
  bool get hasCoordinates =>
      latitude != null && longitude != null && (latitude != 0 || longitude != 0);

  Address copyWith({String? addressLine, double? latitude, double? longitude}) {
    return Address(
      addressLine: addressLine ?? this.addressLine,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
