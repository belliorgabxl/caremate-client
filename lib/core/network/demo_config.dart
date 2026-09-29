import 'package:dio/dio.dart';

import '../config/app_config.dart';

/// Server-configured App Store review bypass account (`GET
/// /config/demo-account`) — replaces what used to be a hardcoded Dart
/// `const` shipped in the client binary, so it can be rotated on the backend
/// without an app rebuild/re-review. [load] is fired once at startup
/// (`main.dart`); on any failure both fields stay null, meaning demo mode
/// simply never triggers this session — fail closed, never fall back to a
/// baked-in value.
class DemoConfig {
  DemoConfig._();

  static String? phone;
  static String? otp;

  static Future<void> load() async {
    try {
      final dio = Dio(BaseOptions(baseUrl: AppConfig.apiBaseUrl));
      final response = await dio.get('/config/demo-account');
      final envelope = response.data;
      final payload =
          (envelope is Map && envelope['data'] is Map
              ? envelope['data']
              : envelope)
          as Map?;

      final fetchedPhone = payload?['phone'] as String?;
      final fetchedOtp = payload?['otp'] as String?;
      if (fetchedPhone != null && fetchedPhone.isNotEmpty) {
        phone = fetchedPhone;
      }
      if (fetchedOtp != null && fetchedOtp.isNotEmpty) otp = fetchedOtp;
    } on DioException {
      // Backend unreachable — demo mode just won't trigger for this session.
    }
  }
}
