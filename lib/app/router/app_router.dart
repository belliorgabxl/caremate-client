import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verify_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/booking/presentation/pages/booking_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/members/presentation/pages/members_page.dart';
import '../../features/payment/presentation/pages/payment_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
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
      final isOtp = path == AppRoutes.otpVerify;
      final isRegister = path == AppRoutes.register;
      final isPreAuth = isLogin || isOtp || isRegister;

      switch (auth.step) {
        case AuthStep.checking:
          return isSplash ? null : AppRoutes.splash;
        case AuthStep.phoneEntry:
          return isLogin ? null : AppRoutes.login;
        case AuthStep.otpSent:
          if (auth.pendingPhone == null) return AppRoutes.login;
          return isOtp ? null : AppRoutes.otpVerify;
        case AuthStep.needsRegistration:
          if (auth.pendingPhone == null) return AppRoutes.login;
          return isRegister ? null : AppRoutes.register;
        case AuthStep.authenticated:
          return (isSplash || isPreAuth) ? AppRoutes.home : null;
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
        path: AppRoutes.otpVerify,
        builder: (context, state) => const OtpVerifyPage(),
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
    ],
  );
});