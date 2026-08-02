class AppConfig {
  const AppConfig._();

  static const maxRelatives = 5;
  static const platformFee = 20.0;
  static const billingStepMinutes = 30;

  /// care-mate-backend (Go/Fiber), called directly — no more Next.js proxy.
  /// `10.0.2.2` is the Android-emulator-only alias for the host machine's
  /// `localhost`; a physical device would need the host's LAN IP instead.
  static const webBaseUrl = 'http://10.0.2.2:3001';
  static const apiBaseUrl = '$webBaseUrl/api/v1';

  /// Recipient PromptPay ID for QR generation (mirrors caremate-client's
  /// `PROMPTPAY_ID` env var — there's no backend endpoint for this).
  static const promptPayId = '6352421543';
}
