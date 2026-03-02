import 'package:dio/dio.dart';

import '../../core/config/app_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/media_item_model.dart';
import 'mock_datasource.dart';

/// Lấy danh sách media (image + video) từ API standee hoặc mock data.
class RemoteMediaDataSource {
  RemoteMediaDataSource({Dio? dio}) : _dio = dio ?? DioClient.I.client;

  final Dio _dio;

  Future<List<MediaItem>> fetchMediaList() async {
    // Nếu dùng mock data
    if (AppConfig.useMockData) {
      await MockDataSource.I.init();
      return MockDataSource.I.getMediaList();
    }

    // Gọi API thật
    final res = await _dio.get(ApiConstants.playlistPath);
    final data = res.data;
    final list = _extractPosterList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => _mapPosterToMedia(e))
        .whereType<MediaItem>()
        .toList();
  }

  /// API có thể trả nhiều kiểu nested; hàm này cố gắng tìm List đầu tiên chứa poster.
  List<dynamic> _extractPosterList(dynamic value, [int depth = 0]) {
    if (value == null) return const [];
    if (value is List) return value;
    if (value is! Map) return const [];
    if (depth > 4) return const [];

    for (final key in const ['result', 'data', 'items', 'posters', 'activePosters']) {
      final v = value[key];
      if (v is List) return v;
      if (v is Map) {
        final nested = _extractPosterList(v, depth + 1);
        if (nested.isNotEmpty) return nested;
      }
    }

    for (final v in value.values) {
      if (v is List) return v;
      if (v is Map) {
        final nested = _extractPosterList(v, depth + 1);
        if (nested.isNotEmpty) return nested;
      }
    }
    return const [];
  }

  MediaItem? _mapPosterToMedia(Map<String, dynamic> json) {
    String? url = json['posterURL'] as String? ??
        json['url'] as String? ??
        json['mediaUrl'] as String? ??
        json['imageUrl'] as String? ??
        json['src'] as String?;

    final media = json['media'];
    if (url == null && media is Map) {
      url = media['url'] as String? ??
          media['mediaUrl'] as String? ??
          media['src'] as String?;
    }
    if (url == null || url.isEmpty) return null;

    // Chuẩn hoá absolute URL
    if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('asset:')) {
      final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '');
      final path = url.startsWith('/') ? url : '/$url';
      url = '$base$path';
    }

    // Loại media
    String typeStr = (json['type'] ?? '').toString().toLowerCase();
    if (typeStr.isEmpty) {
      if (url.endsWith('.mp4') || url.endsWith('.webm')) {
        typeStr = 'video';
      } else {
        typeStr = 'image';
      }
    }

    final type = typeStr == 'video' ? MediaType.video : MediaType.image;

    final duration =
        (json['duration'] ?? json['displayDuration'] ?? json['durationSeconds']) as int? ?? 10;

    return MediaItem(
      url: url,
      type: type,
      durationSeconds: duration > 0 ? duration : 10,
    );
  }
}
