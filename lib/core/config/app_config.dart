class AppConfig {
  const AppConfig._();

  static const maxRelatives = 5;
  static const platformFee = 20.0;
  static const billingStepMinutes = 30;

  /// care-mate-backend (Go/Fiber), called directly — no more Next.js proxy.
  /// Override per target at build time, since the host that resolves to the
  /// dev machine differs by platform:
  ///
  ///   iOS simulator / macOS  → default below
  ///   Android emulator       → --dart-define=API_HOST=http://10.0.2.2:8084
  ///   physical device        → --dart-define=API_HOST=http://LAN-IP:8084
  ///
  /// `8084` mirrors `APP_PORT` in care-mate-backend's `.env`.
  static const webBaseUrl = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'http://localhost:8084',
  );
  static const apiBaseUrl = '$webBaseUrl/api/v1';

  /// Recipient PromptPay ID for QR generation (mirrors caremate-client's
  /// `PROMPTPAY_ID` env var — there's no backend endpoint for this).
  static const promptPayId = '6352421543';
}
