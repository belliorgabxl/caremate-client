import 'package:flutter/foundation.dart';

/// Global on/off switch for the App Store review demo account
/// ([AppConfig.demoPhone]/[AppConfig.demoOtp]). `AuthController` flips this
/// on right before the demo phone's OTP request, and back off on logout —
/// while it's true, [DemoInterceptor] answers every Dio call from
/// [DemoBackend]'s in-memory fixtures instead of reaching the real network,
/// so a reviewer can exercise every screen with no live backend involved.
class DemoMode {
  DemoMode._();

  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);
}
