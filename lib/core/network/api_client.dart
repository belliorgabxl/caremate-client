import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/local_storage.dart';

/// Thin wrapper around Dio pointed at caremate-client's `/api/*` BFF routes.
/// Auth is a single HttpOnly `caremate_session` cookie set by the backend on
/// `/auth/login` and `/auth/register`; Dio just replays it on every call.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._localStorage)
    : dio = Dio(
        BaseOptions(
          baseUrl: AppConfig.apiBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {'Accept': 'application/json'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final cookie = await _localStorage.readSessionCookie();
          if (cookie != null) {
            options.headers['Cookie'] = cookie;
          }
          handler.next(options);
        },
      ),
    );
  }

  final Dio dio;
  final LocalStorage _localStorage;

  /// caremate-client's backend responses inconsistently wrap the payload as
  /// `data`, `Data`, or `result` (or not at all) — unwrap defensively.
  dynamic unwrap(dynamic body) {
    if (body is Map<String, dynamic>) {
      return body['data'] ?? body['Data'] ?? body['result'] ?? body;
    }
    return body;
  }

  /// Error responses are inconsistently shaped upstream: most use the
  /// `{ success, error }` envelope from `pkg/response`, but a couple of
  /// handlers (e.g. `AuthMe`'s 401) hand-roll `{ message }` instead.
  Never throwApiException(DioException error) {
    final data = error.response?.data;
    final message =
        (data is Map<String, dynamic> ? data['error'] as String? : null) ??
        (data is Map<String, dynamic> ? data['message'] as String? : null) ??
        error.message ??
        'เกิดข้อผิดพลาดในการเชื่อมต่อ';
    throw ApiException(message, statusCode: error.response?.statusCode);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref.read(localStorageProvider));
});
