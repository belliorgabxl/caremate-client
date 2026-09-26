import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/booking/presentation/pages/booking_history_page.dart';
import '../../features/booking/presentation/pages/booking_page.dart';
import '../../features/booking/presentation/pages/booking_status_page.dart';
import '../../features/booking/presentation/pages/public_tracking_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/members/presentation/pages/members_page.dart';
import '../../features/notifications/presentation/pages/notification_center_page.dart';
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/payment/presentation/pages/payment_success_page.dart';
import '../../features/profile/presentation/pages/addresses_page.dart';
import '../../features/profile/presentation/pages/bank_account_page.dart';
import '../../features/profile/presentation/pages/health_information_page.dart';
import '../../features/profile/presentation/pages/personal_information_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/support/presentation/pages/help_center_page.dart';
import '../../shared/models/booking.dart';
import '../../shared/models/booking_prefill.dart';
import '../../shared/widgets/main_scaffold.dart';
import 'app_routes.dart';
import 'nav_direction.dart';

/// Every route change is an instant cut — no slide, no fade. [navDirection]
/// is still reset here so a stale `back` value from
/// [GoRouterBackExtension.goBack] never leaks into an unrelated later
/// navigation; nothing currently reads the direction for the transition
/// itself.
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
CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  navDirection.value = NavDirection.forward;

  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: Duration.zero,
    reverseTransitionDuration: Duration.zero,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        child,
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
      // Meant to be opened by whoever received the share link, logged in or
      // not — never gate this behind auth, in either direction.
      final isPublicTracking = path.startsWith('/track/');
      if (isPublicTracking) return null;

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
            pageBuilder: (context, state) => _slidePage(
              state,
              BookingPage(
                prefill: state.extra is BookingPrefill
                    ? state.extra as BookingPrefill
                    : null,
              ),
            ),
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
        pageBuilder: (context, state) => _slidePage(state, const PaymentPage()),
      ),
      GoRoute(
        path: AppRoutes.paymentSuccess,
        pageBuilder: (context, state) => _slidePage(
          state,
          PaymentSuccessPage(booking: state.extra as Booking),
        ),
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
        path: AppRoutes.profileBankAccount,
        pageBuilder: (context, state) =>
            _slidePage(state, const BankAccountPage()),
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
      GoRoute(
        path: AppRoutes.helpCenter,
        pageBuilder: (context, state) =>
            _slidePage(state, const HelpCenterPage()),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        pageBuilder: (context, state) =>
            _slidePage(state, const NotificationCenterPage()),
      ),
      GoRoute(
        path: AppRoutes.publicTracking,
        pageBuilder: (context, state) => _slidePage(
          state,
          PublicTrackingPage(token: state.pathParameters['token']!),
        ),
      ),
    ],
  );
});
