class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const booking = '/booking';
  static const members = '/members';
  static const payment = '/payment';
  static const profile = '/profile';
  static const profilePersonalInformation = '/profile/personal-information';
  static const profileHealthInformation = '/profile/health-information';
  static const profileAddresses = '/profile/addresses';
  static const profileSettings = '/profile/settings';
  static const bookingHistory = '/booking/history';
  static const bookingStatus = '/booking/status/:bookingId';
  static const referral = '/profile/referral';
  static const helpCenter = '/profile/help-center';
  static const notifications = '/notifications';
  static const publicTracking = '/track/:token';

  static String bookingStatusPath(String bookingId) => '/booking/status/$bookingId';
  static String publicTrackingPath(String token) => '/track/$token';
}