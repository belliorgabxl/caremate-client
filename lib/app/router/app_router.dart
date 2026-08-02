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
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) => const RegisterPage(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainScaffold(child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: AppRoutes.booking,
            builder: (context, state) => const BookingPage(),
          ),
          GoRoute(
            path: AppRoutes.members,
            builder: (context, state) => const MembersPage(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.payment,
        builder: (context, state) => const PaymentPage(),
      ),
      GoRoute(
        path: AppRoutes.profilePersonalInformation,
        builder: (context, state) => const PersonalInformationPage(),
      ),
      GoRoute(
        path: AppRoutes.profileHealthInformation,
        builder: (context, state) => const HealthInformationPage(),
      ),
      GoRoute(
        path: AppRoutes.profileAddresses,
        builder: (context, state) => const AddressesPage(),
      ),
      GoRoute(
        path: AppRoutes.profileSettings,
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: AppRoutes.bookingHistory,
        builder: (context, state) => const BookingHistoryPage(),
      ),
      GoRoute(
        path: AppRoutes.bookingStatus,
        builder: (context, state) => BookingStatusPage(
          bookingId: state.pathParameters['bookingId']!,
          seed: state.extra is Booking ? state.extra as Booking : null,
        ),
      ),
    ],
  );
});