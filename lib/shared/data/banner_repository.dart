import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../models/banner_item.dart';

/// `GET /banners` — public, no auth needed.
class BannerRepository {
  BannerRepository(this._api);

  final ApiClient _api;

  Future<List<BannerItem>> getActive() async {
    try {
      final response = await _api.dio.get('/banners');
      final unwrapped = _api.unwrap(response.data);
      final items = unwrapped is List
          ? unwrapped
          : (unwrapped is Map<String, dynamic>
              ? (unwrapped['banners'] as List<dynamic>? ?? const [])
              : const []);

      return [
        for (final item in items) BannerItem.fromJson(item as Map<String, dynamic>),
      ];
    } on DioException catch (e) {
      _api.throwApiException(e);
    }
  }
}

final bannerRepositoryProvider = Provider<BannerRepository>((ref) {
  return BannerRepository(ref.read(apiClientProvider));
});
