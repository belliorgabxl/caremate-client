import 'app_user.dart';

enum OtpVerifyStatus { loginSuccess, registerRequired }

class OtpVerifyResult {
  const OtpVerifyResult._(this.status, {this.user, this.phone});

  final OtpVerifyStatus status;
  final AppUser? user;
  final String? phone;

  bool get isLoginSuccess => status == OtpVerifyStatus.loginSuccess;

  factory OtpVerifyResult.loginSuccess(AppUser user) =>
      OtpVerifyResult._(OtpVerifyStatus.loginSuccess, user: user);

  factory OtpVerifyResult.registerRequired(String phone) =>
      OtpVerifyResult._(OtpVerifyStatus.registerRequired, phone: phone);
}
