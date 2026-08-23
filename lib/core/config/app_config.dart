class AppConfig {
  const AppConfig._();

  static const maxRelatives = 5;
  static const platformFee = 20.0;
  static const billingStepMinutes = 30;

  /// care-mate-backend (Go/Fiber), called directly — no more Next.js proxy.
  /// `10.0.2.2` is the Android-emulator-only alias for the host machine's
  /// `localhost`; a physical device would need the host's LAN IP instead.
  ///  webBaseUrl = 'http://10.0.2.2:3001';
  ///  host = 'https://caremate-backend.nattavee.com';
  static const webBaseUrl = 'https://caremate-backend.nattavee.com';
  static const apiBaseUrl = '$webBaseUrl/api/v1';

  /// Recipient PromptPay ID for QR generation (mirrors caremate-client's
  /// `PROMPTPAY_ID` env var — there's no backend endpoint for this).
  static const promptPayId = '6352421543';

  /// Google Maps / Places key. The map itself doesn't read this — Android
  /// takes it from `android/local.properties` via the manifest and iOS from
  /// `AppDelegate.swift` — but the Places SDK is initialized from Dart, so it
  /// needs the value here too. Restrict it in Cloud Console (Android package
  /// + SHA-1, iOS bundle ID); a client key is always extractable from the app.
  static const googlePlacesApiKey = 'AIzaSyD7Kw_w4HSkFrfjIULXFXBAzCtYGnamYA8';

  /// Autocomplete is biased to Thailand — the app only operates there, and an
  /// unrestricted prediction list is mostly noise for Thai queries.
  static const placesCountries = ['th'];
}
