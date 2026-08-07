import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/booking/presentation/pages/booking_history_page.dart';
import '../../features/booking/presentation/pages/booking_page.dart';
import '../../features/booking/presentation/pages/booking_status_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/members/presentation/pages/members_page.dart';
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/profile/presentation/pages/addresses_page.dart';
import '../../features/profile/presentation/pages/health_information_page.dart';
import '../../features/profile/presentation/pages/personal_information_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../shared/models/booking.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'app_routes.dart';
import 'nav_direction.dart';

/// Every ordinary navigation (any plain `context.go()`, or explicitly via
/// [GoRouterBackExtension.goForward]) slides the new page in from the right
/// (right → left). Only an explicit "return to the previous screen" action
/// — anything that navigates via [GoRouterBackExtension.goBack] — slides
/// the new (previous) page in from the left (left → right) instead. Since
/// this app never uses `push`/`pop` (see CLAUDE.md), Flutter has no real
/// navigation stack to auto-derive that distinction from, hence
/// [navDirection] as an explicit signal, read once per page build then
/// reset to forward.
///
/// Applied to every route in this router, *including* the four bottom-tab
/// routes inside the `ShellRoute` below. Those cannot use the `builder` +
/// an `AnimatedSwitcher` wrapped around `ShellRoute`'s own `child` (tried
/// first) — `ShellRoute` hands its `builder` the *same* `Navigator` Element
/// (same `GlobalKey`) on every rebuild regardless of which tab is active,
/// so a transition wrapped around that `child` never has an "old vs new"
/// widget pair to animate between; the only place a transition is actually
/// visible is the shell's own *inner* Navigator (a real, distinct Navigator
/// per `ShellRoute`, with working Page transitions), i.e. right here.
/// `MainScaffold._onTap` sets [navDirection] by comparing the tapped tab's
/// index to the current one before calling `context.go()`.
CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  final isBack = navDirection.value == NavDirection.back;
  navDirection.value = NavDirection.forward;

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final entrance = Tween<Offset>(
        begin: Offset(isBack ? -1 : 1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic)).animate(animation);
      return SlideTransition(position: entrance, child: child);
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final auth = ref.read(authControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;

      final isSplash = path == AppRoutes.splash;
      final isLogin = path == AppRoutes.login;
      final isRegister = path == AppRoutes.register;

      switch (auth.step) {
        case AuthStep.checking:
          return isSplash ? null : AppRoutes.splash;
        case AuthStep.loggedOut:
          return (isLogin || isRegister) ? null : AppRoutes.login;
        case AuthStep.authenticated:
          return (isSplash || isLogin || isRegister) ? AppRoutes.home : null;
      }
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => _slidePage(state, const SplashPage()),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => _slidePage(state, const LoginPage()),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) =>
            _slidePage(state, const RegisterPage()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            pageBuilder: (context, state) =>
                _slidePage(state, const HomePage()),
          ),
          GoRoute(
            path: AppRoutes.booking,
            pageBuilder: (context, state) =>
                _slidePage(state, const BookingPage()),
          ),
          GoRoute(
            path: AppRoutes.members,
            pageBuilder: (context, state) =>
                _slidePage(state, const MembersPage()),
          ),
          GoRoute(
            path: AppRoutes.profile,
            pageBuilder: (context, state) =>
                _slidePage(state, const ProfilePage()),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.payment,
        pageBuilder: (context, state) =>
            _slidePage(state, const PaymentPage()),
      ),
      GoRoute(
        path: AppRoutes.profilePersonalInformation,
        pageBuilder: (context, state) =>
            _slidePage(state, const PersonalInformationPage()),
      ),
      GoRoute(
        path: AppRoutes.profileHealthInformation,
        pageBuilder: (context, state) =>
            _slidePage(state, const HealthInformationPage()),
      ),
      GoRoute(
        path: AppRoutes.profileAddresses,
        pageBuilder: (context, state) =>
            _slidePage(state, const AddressesPage()),
      ),
      GoRoute(
        path: AppRoutes.profileSettings,
        pageBuilder: (context, state) =>
            _slidePage(state, const SettingsPage()),
      ),
      GoRoute(
        path: AppRoutes.bookingHistory,
        pageBuilder: (context, state) =>
            _slidePage(state, const BookingHistoryPage()),
      ),
      GoRoute(
        path: AppRoutes.bookingStatus,
        pageBuilder: (context, state) => _slidePage(
          state,
          BookingStatusPage(
            bookingId: state.pathParameters['bookingId']!,
            seed: state.extra is Booking ? state.extra as Booking : null,
          ),
        ),
      ),
    ],
  );
});