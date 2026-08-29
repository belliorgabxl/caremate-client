/// Result of `POST /payments/:paymentId/charge` — a Beam QR PromptPay charge.
/// `qrImageBase64` is a ready-to-render PNG straight from Beam, not an EMV
/// payload string; decode and display it directly.
class ChargeInfo {
  const ChargeInfo({
    required this.paymentId,
    required this.chargeId,
    required this.qrImageBase64,
    this.qrExpiresAt,
  });

  final String paymentId;
  final String chargeId;
  final String qrImageBase64;
  final DateTime? qrExpiresAt;

  factory ChargeInfo.fromJson(Map<String, dynamic> json) {
    final expiresRaw = json['qrExpiresAt'] as String?;

    return ChargeInfo(
      paymentId: json['paymentId'] as String? ?? '',
      chargeId: json['chargeId'] as String? ?? '',
      qrImageBase64: json['qrImageBase64'] as String? ?? '',
      qrExpiresAt: expiresRaw == null ? null : DateTime.tryParse(expiresRaw),
    );
  }
}
