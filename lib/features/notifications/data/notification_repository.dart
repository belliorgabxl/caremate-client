import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/models/notification_item.dart';

class NotificationRepository {
  NotificationRepository(this._api);

  final ApiClient _api;

  Future<(List<NotificationItem>, int)> list({int page = 1}) async {
    try {
      final response = await _api.dio.get(
        '/notifications',
        queryParameters: {'page': page},
      );
      final data = _api.unwrap(response.data) as Map<String, dynamic>;
      final rows = (data['notifications'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(NotificationItem.fromJson)
          .toList(growable: false);
      final unread = (data['unread_count'] as num?)?.toInt() ?? 0;
      return (rows, unread);
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }

  Future<void> markRead(String id) async {
    try {
      await _api.dio.patch('/notifications/$id/read');
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.read(apiClientProvider));
});
