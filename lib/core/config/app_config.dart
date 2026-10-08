class AppConfig {
  const AppConfig._();

  static const maxRelatives = 5;
  static const billingStepMinutes = 30;

  /// care-mate-backend (Go/Fiber), called directly — no more Next.js proxy.
  /// `10.0.2.2` is the Android-emulator-only alias for the host machine's
  /// `localhost`; a physical device would need the host's LAN IP instead.
  // Apple rejected both CareMateClient and CareMatePartner (Guideline
  // 2.1(a) — App Completeness) because this was still pointed at
  // 10.0.2.2:3001, the Android-emulator-only alias for a dev machine's own
  // localhost — unreachable from a reviewer's real device. The deployed
  // backend now has the Beam payment code (confirmed live), so this points
  // there instead. For local emulator development, override with
  // `flutter run --dart-define=WEB_BASE_URL=http://10.0.2.2:3001`.
  static const webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://api.caremate.in.th',
  );
  static const apiBaseUrl = '$webBaseUrl/api/v1';

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
