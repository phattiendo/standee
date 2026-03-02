import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/air_quality_model.dart';
import '../models/media_item_model.dart';
import '../models/speed_test_model.dart';
import '../models/standee_info_model.dart';
import '../models/weather_model.dart';

/// Singleton datasource để load và cung cấp mock data từ JSON file.
/// Dùng cho demo/testing khi không có API thật.
class MockDataSource {
  MockDataSource._();
  static final MockDataSource I = MockDataSource._();

  static const String _mockDataPath = 'assets/mock/mock_data.json';

  Map<String, dynamic>? _data;
  bool _initialized = false;

  /// Khởi tạo và load mock data từ assets
  Future<void> init() async {
    if (_initialized) return;

    try {
      final jsonString = await rootBundle.loadString(_mockDataPath);
      _data = json.decode(jsonString) as Map<String, dynamic>;
      _initialized = true;
      debugPrint('MockDataSource: Loaded mock data successfully');
    } catch (e) {
      debugPrint('MockDataSource: Failed to load mock data - $e');
      _data = {};
      _initialized = true;
    }
  }

  /// Lấy Weather data
  WeatherData getWeather() {
    final weatherJson = _data?['weather'] as Map<String, dynamic>?;
    if (weatherJson == null) return WeatherData.empty();
    return WeatherData.fromJson(weatherJson);
  }

  /// Lấy Air Quality data
  AirQualityData getAirQuality() {
    final aqJson = _data?['airQuality'] as Map<String, dynamic>?;
    if (aqJson == null) return AirQualityData.empty();
    return AirQualityData.fromJson(aqJson);
  }

  /// Lấy Speed Test data
  SpeedTestData getSpeedTest() {
    final speedJson = _data?['speedTest'] as Map<String, dynamic>?;
    if (speedJson == null) return SpeedTestData.empty();
    return SpeedTestData.fromJson(speedJson);
  }

  /// Lấy Standee Info
  StandeeInfo getStandeeInfo() {
    final infoJson = _data?['standeeInfo'] as Map<String, dynamic>?;
    if (infoJson == null) return StandeeInfo.empty();
    return StandeeInfo.fromJson(infoJson);
  }

  /// Lấy danh sách Media items
  List<MediaItem> getMediaList() {
    final mediaList = _data?['mediaList'] as List<dynamic>?;
    if (mediaList == null) return [];

    return mediaList
        .whereType<Map<String, dynamic>>()
        .map((e) => MediaItem.fromJson(e))
        .toList();
  }

  /// Reset mock data (useful for testing)
  void reset() {
    _data = null;
    _initialized = false;
  }
}
