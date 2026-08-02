/// Ports the EMVCo "Thai QR Payment Standard" (PromptPay) payload builder —
/// the same algorithm caremate-client's Next.js proxy used via the
/// `promptpay-qr` npm package — since the Go backend has no equivalent
/// endpoint. Given the same target id + amount, produces a byte-identical
/// payload to what that package generated.
library;

enum _TargetType { msisdn, nationalId, eWalletId }

class _Target {
  const _Target(this.type, this.value);
  final _TargetType type;
  final String value;
}

String generatePromptPayPayload({required String promptPayId, required double amount}) {
  final target = _sanitizeTarget(promptPayId);

  final merchantAccountInfo = switch (target.type) {
    _TargetType.eWalletId => _tlv('00', 'A000000677010112') + _tlv('02', target.value),
    _TargetType.nationalId => _tlv('00', 'A000000677010111') + _tlv('02', target.value),
    _TargetType.msisdn => _tlv('00', 'A000000677010111') + _tlv('01', target.value),
  };

  final payloadWithoutCrc = '${_tlv('00', '01')}' // Payload Format Indicator
      '${_tlv('01', '12')}' // Point of Initiation Method: dynamic (has an amount)
      '${_tlv('29', merchantAccountInfo)}' // Merchant Account Info (PromptPay)
      '${_tlv('53', '764')}' // Transaction Currency: THB
      '${_tlv('54', amount.toStringAsFixed(2))}' // Transaction Amount
      '${_tlv('58', 'TH')}' // Country Code
      '6304'; // CRC tag + length; value appended below

  final crc = _crc16(payloadWithoutCrc).toRadixString(16).toUpperCase().padLeft(4, '0');
  return '$payloadWithoutCrc$crc';
}

_Target _sanitizeTarget(String id) {
  final numbers = id.replaceAll(RegExp(r'[^0-9]'), '');

  if (numbers.length >= 15) return _Target(_TargetType.eWalletId, numbers);
  if (numbers.length >= 13) return _Target(_TargetType.nationalId, numbers);
  return _Target(_TargetType.msisdn, numbers.replaceFirst(RegExp(r'^0'), '66'));
}

String _tlv(String tag, String value) => '$tag${value.length.toString().padLeft(2, '0')}$value';

int _crc16(String data) {
  var crc = 0xFFFF;
  for (final byte in data.codeUnits) {
    crc ^= byte << 8;
    for (var i = 0; i < 8; i++) {
      crc = (crc & 0x8000) != 0 ? ((crc << 1) ^ 0x1021) & 0xFFFF : (crc << 1) & 0xFFFF;
    }
  }
  return crc;
}
