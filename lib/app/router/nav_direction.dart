import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Route transitions are a plain cross-fade for every navigation now (see
/// `app_router.dart`'s `_slidePage`) — this no longer drives a directional
/// slide. Kept only as a semantic marker of navigation *intent* ("this call
/// is a return to the previous screen" vs. "this call goes deeper into the
/// app"), which call sites still express via [BuildContext.goBack] vs.
/// [BuildContext.goForward] instead of bare `context.go()`.
enum NavDirection { forward, back }

final navDirection = ValueNotifier<NavDirection>(NavDirection.forward);

extension GoRouterBackExtension on BuildContext {
  /// Navigate to [location] as a "return to the previous screen" action — a
  /// `BackButton`, an app bar back arrow, or an action whose own label says
  /// "return"/"back" (e.g. "กลับหน้าหลัก", "save and return to the previous
  /// screen"). See [NavDirection].
  void goBack(String location, {Object? extra}) {
    navDirection.value = NavDirection.back;
    GoRouter.of(this).go(location, extra: extra);
  }

  /// Navigate to [location] as an ordinary action that moves deeper into
  /// the app (not a tab-bar tap, which has its own logic in
  /// `MainScaffold._onTap`). Plain `context.go()` already defaults to this,
  /// but [navDirection] can be left over as `back` from a prior `goBack()`
  /// call — use this instead of bare `go()` to reset that intent marker.
  void goForward(String location, {Object? extra}) {
    navDirection.value = NavDirection.forward;
    GoRouter.of(this).go(location, extra: extra);
  }

  /// Pushes [location] onto the navigation stack instead of replacing the
  /// current location the way [goForward]/`go()` do. Use this for a page
  /// that can be opened from more than one place (booking status, payment,
  /// notifications, any profile sub-page) so its own back button — via
  /// [popBack] — returns to wherever it was actually opened from, instead of
  /// a single hardcoded parent. Never use this for the four bottom-tab
  /// routes themselves (Home/Booking/Members/Profile): those are tab
  /// switches, not a stack to push onto — keep using [goForward] there.
  void pushForward(String location, {Object? extra}) {
    navDirection.value = NavDirection.forward;
    GoRouter.of(this).push(location, extra: extra);
  }

  /// Returns to wherever this screen was pushed from via [pushForward]. Falls
  /// back to [fallback] (via [goBack]) when there's nothing to pop to — e.g.
  /// this screen was reached directly with no pushed history (a cold start
  /// redirect, a future deep link). Pair every [pushForward] call site with
  /// a [popBack] on the page it opens; a page still reachable via a plain
  /// [goForward] should keep using [goBack] instead.
  void popBack(String fallback, {Object? extra}) {
    final router = GoRouter.of(this);
    if (router.canPop()) {
      navDirection.value = NavDirection.back;
      router.pop();
    } else {
      goBack(fallback, extra: extra);
    }
  }
}
