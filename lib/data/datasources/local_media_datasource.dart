import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/media_item_model.dart';

/// Lưu danh sách media vào Hive để dùng offline.
class LocalMediaDataSource {
  static const String _boxName = 'media_cache_box';
  static const String _keyMediaList = 'media_list';

  Box<String>? _box;
  bool _initialized = false;
  bool _initializing = false;

  Future<void> init() async {
    if (_initialized || _initializing) return;
    _initializing = true;

    try {
      _box = await Hive.openBox<String>(_boxName).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('LocalMediaDataSource: Hive open timeout');
          throw Exception('Hive timeout');
        },
      );
      _initialized = true;
      debugPrint('LocalMediaDataSource: initialized');
    } catch (e) {
      debugPrint('LocalMediaDataSource init error: $e');
    } finally {
      _initializing = false;
    }
  }

  Future<List<MediaItem>> loadCachedMedia() async {
    if (_box == null) return const [];

    try {
      final jsonStr = _box!.get(_keyMediaList);
      if (jsonStr == null) return const [];

      final decoded = jsonDecode(jsonStr);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map((e) => MediaItem.fromJson(e))
          .toList();
    } catch (e) {
      debugPrint('Load cache error: $e');
      return const [];
    }
  }

  Future<void> saveMedia(List<MediaItem> items) async {
    if (_box == null || items.isEmpty) return;

    try {
      final list = items.map((e) => e.toJson()).toList();
      await _box!.put(_keyMediaList, jsonEncode(list));
    } catch (e) {
      debugPrint('Save cache error: $e');
    }
  }
}
