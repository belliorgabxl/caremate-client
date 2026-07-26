class AppConfig {
  const AppConfig._();

  static const otpLength = 6;
  static const otpTtl = Duration(minutes: 5);
  static const otpResendCooldown = Duration(seconds: 30);

  static const maxRelatives = 5;
  static const platformFee = 20.0;
  static const billingStepMinutes = 30;

  static const mockNetworkDelay = Duration(milliseconds: 600);

  /// Phone number that already exists in the simulated user directory, so the
  /// login-vs-register branch of the OTP flow can both be demoed.
  static const demoExistingPhone = '0812345678';
}
