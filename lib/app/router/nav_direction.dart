import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// This app always navigates with `context.go()` (see CLAUDE.md — never
/// `push`/`pop`), so Flutter's Navigator never sees a real push/pop stack
/// to auto-derive a forward vs. back page transition from. This flag is the
/// explicit substitute: [BuildContext.goBack] sets it right before a
/// "return to the previous screen" navigation (a `BackButton`, an app bar
/// back arrow), the router's page-transition builder reads and consumes it
/// once, and every other, ordinary `context.go()` call falls back to
/// forward.
enum NavDirection { forward, back }

final navDirection = ValueNotifier<NavDirection>(NavDirection.forward);

extension GoRouterBackExtension on BuildContext {
  /// Navigate to [location] using the "back" (left ← right entrance)
  /// page transition instead of the default forward (right ← left) one.
  /// Use only for genuine "return to the previous screen" actions — a
  /// `BackButton`, an app bar back arrow, or an action whose own label says
  /// "return"/"back" (e.g. "กลับหน้าหลัก", "save and return to the previous
  /// screen").
  void goBack(String location, {Object? extra}) {
    navDirection.value = NavDirection.back;
    GoRouter.of(this).go(location, extra: extra);
  }

  /// Navigate to [location] using the "forward" (right ← left entrance)
  /// transition, explicitly — for ordinary action buttons that move deeper
  /// into the app (not a tab-bar tap, which has its own left/right-aware
  /// logic in `MainScaffold._onTap`). Plain `context.go()` already defaults
  /// to forward, but [navDirection] can be left over as `back` from a prior
  /// `goBack()` call — use this instead of bare `go()` wherever a stale
  /// `back` value would visibly flip this button's transition the wrong way.
  void goForward(String location, {Object? extra}) {
    navDirection.value = NavDirection.forward;
    GoRouter.of(this).go(location, extra: extra);
  }
}
