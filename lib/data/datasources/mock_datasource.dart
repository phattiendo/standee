import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/config/app_config.dart';
import '../models/air_quality_model.dart';
import '../models/media_item_model.dart';
import '../models/speed_test_model.dart';
import '../models/standee_info_model.dart';
import '../models/weather_model.dart';

/// Mock DataSource - load data từ JSON file trong assets
/// Dùng để test app offline hoặc demo cho mentor
class MockDataSource {
  MockDataSource._();
  static final MockDataSource I = MockDataSource._();

  Map<String, dynamic>? _cachedData;
  bool _initialized = false;

  /// Load mock data từ assets
  Future<void> init() async {
    if (_initialized) return;

    try {
      final jsonStr = await rootBundle.loadString(AppConfig.mockDataPath);
      _cachedData = jsonDecode(jsonStr) as Map<String, dynamic>;
      _initialized = true;
    } catch (e) {
      _cachedData = {};
      _initialized = true;
    }
  }

  /// Lấy Weather data
  WeatherData getWeather() {
    if (_cachedData == null) return WeatherData.empty();

    final weatherJson = _cachedData!['weather'] as Map<String, dynamic>?;
    if (weatherJson == null) return WeatherData.empty();

    return WeatherData.fromJson(weatherJson);
  }

  /// Lấy Air Quality data
  AirQualityData getAirQuality() {
    if (_cachedData == null) return AirQualityData.empty();

    final aqiJson = _cachedData!['airQuality'] as Map<String, dynamic>?;
    if (aqiJson == null) return AirQualityData.empty();

    return AirQualityData.fromJson(aqiJson);
  }

  /// Lấy Speed Test data
  SpeedTestData getSpeedTest() {
    if (_cachedData == null) return SpeedTestData.empty();

    final speedJson = _cachedData!['speedTest'] as Map<String, dynamic>?;
    if (speedJson == null) return SpeedTestData.empty();

    final result = speedJson['result'] as List<dynamic>?;
    if (result == null || result.isEmpty) return SpeedTestData.empty();

    return SpeedTestData.getLatestFromList(result) ?? SpeedTestData.empty();
  }

  /// Lấy Standee Info
  StandeeInfo getStandeeInfo() {
    if (_cachedData == null) return StandeeInfo.empty();

    final standeeJson = _cachedData!['standeeInfo'] as Map<String, dynamic>?;
    if (standeeJson == null) return StandeeInfo.empty();

    return StandeeInfo.fromJson(standeeJson);
  }

  /// Lấy Media List (posters)
  List<MediaItem> getMediaList() {
    if (_cachedData == null) return [];

    final mediaList = _cachedData!['mediaList'] as List<dynamic>?;
    if (mediaList == null) return [];

    return mediaList
        .whereType<Map<String, dynamic>>()
        .map((e) => MediaItem.fromJson(e))
        .toList();
  }
}
