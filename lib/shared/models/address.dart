class Address {
  const Address({
    required this.addressLine,
    this.latitude,
    this.longitude,
  });

  final String addressLine;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  Address copyWith({String? addressLine, double? latitude, double? longitude}) {
    return Address(
      addressLine: addressLine ?? this.addressLine,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }
}
