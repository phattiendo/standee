import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/media_item_model.dart';

/// Lấy danh sách media (image + video) từ API standee.
class RemoteMediaDataSource {
  RemoteMediaDataSource({Dio? dio}) : _dio = dio ?? DioClient.I.client;

  final Dio _dio;

  /// GET /api/standee/version → { "version": 7 }
  Future<int> fetchVersion() async {
    try {
      final res = await _dio.get(ApiConstants.versionPath);
      final data = res.data;
      if (data is Map && data['version'] != null) {
        return (data['version'] as num).toInt();
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }

  Future<List<MediaItem>> fetchMediaList() async {
    final res = await _dio.get(ApiConstants.playlistPath);
    final data = res.data;
    final list = _extractPosterList(data);
    return list
        .whereType<Map<String, dynamic>>()
        .map((e) => _mapPosterToMedia(e))
        .whereType<MediaItem>()
        .toList();
  }

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

    if (!url.startsWith('http://') && !url.startsWith('https://') && !url.startsWith('asset:')) {
      final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/$'), '');
      final path = url.startsWith('/') ? url : '/$url';
      url = '$base$path';
    }

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
    final id = (json['id'] ?? json['posterId'] ?? '').toString();

    return MediaItem(
      id: id,
      url: url,
      type: type,
      durationSeconds: duration > 0 ? duration : 10,
    );
  }
}
