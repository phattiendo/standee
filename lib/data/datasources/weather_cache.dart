import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/weather_model.dart';

/// Cache service cho Weather data
class WeatherCache {
  WeatherCache._internal();
  static final WeatherCache _instance = WeatherCache._internal();
  static WeatherCache get I => _instance;

  static const String _boxName = 'weather_cache';
  static const String _weatherKey = 'weather_data';
  static const String _timestampKey = 'weather_timestamp';

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
          debugPrint('WeatherCache: Hive open timeout');
          throw Exception('Hive timeout');
        },
      );
      _initialized = true;
      debugPrint('WeatherCache: initialized');
    } catch (e) {
      debugPrint('WeatherCache init error: $e');
    } finally {
      _initializing = false;
    }
  }

  Future<void> saveWeather(WeatherData weather) async {
    if (_box == null) return;

    try {
      final json = weather.toJson();
      await _box!.put(_weatherKey, jsonEncode(json));
      await _box!.put(_timestampKey, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  Future<WeatherData?> loadWeather() async {
    if (_box == null) return null;

    try {
      final jsonStr = _box!.get(_weatherKey);
      if (jsonStr == null) return null;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WeatherData.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  bool isCacheValid() {
    if (_box == null) return false;

    try {
      final timestampStr = _box!.get(_timestampKey);
      if (timestampStr == null) return false;

      final timestamp = DateTime.parse(timestampStr);
      final age = DateTime.now().difference(timestamp);
      return age.inHours < 1;
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() async {
    try {
      await _box?.delete(_weatherKey);
      await _box?.delete(_timestampKey);
    } catch (_) {}
  }
}
