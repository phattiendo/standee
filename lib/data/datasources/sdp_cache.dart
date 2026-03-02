import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/air_quality_model.dart';
import '../models/speed_test_model.dart';
import '../models/standee_info_model.dart';

/// Cache service cho SDP data
class SdpCache {
  SdpCache._();
  static final SdpCache I = SdpCache._();

  static const String _boxName = 'sdp_cache';
  static const String _aqiKey = 'aqi_data';
  static const String _aqiTimestampKey = 'aqi_timestamp';
  static const String _speedKey = 'speed_data';
  static const String _speedTimestampKey = 'speed_timestamp';
  static const String _standeeKey = 'standee_info';
  static const String _standeeTimestampKey = 'standee_timestamp';

  static const int _cacheValidityMinutes = 30;

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
          debugPrint('SdpCache: Hive open timeout');
          throw Exception('Hive timeout');
        },
      );
      _initialized = true;
      debugPrint('SdpCache: initialized');
    } catch (e) {
      debugPrint('SdpCache init error: $e');
      _initialized = false;
    } finally {
      _initializing = false;
    }
  }

  // ============ Air Quality ============

  Future<void> saveAirQuality(AirQualityData data) async {
    if (_box == null || data.isEmpty) return;
    try {
      await _box!.put(_aqiKey, jsonEncode(data.toJson()));
      await _box!.put(_aqiTimestampKey, DateTime.now().millisecondsSinceEpoch.toString());
    } catch (_) {}
  }

  Future<AirQualityData?> loadAirQuality() async {
    if (_box == null) return null;
    try {
      final jsonStr = _box!.get(_aqiKey);
      if (jsonStr == null) return null;
      return AirQualityData.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  bool isAqiCacheValid() {
    if (_box == null) return false;
    try {
      final timestampStr = _box!.get(_aqiTimestampKey);
      if (timestampStr == null) return false;
      final timestamp = int.tryParse(timestampStr) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      return age < _cacheValidityMinutes * 60 * 1000;
    } catch (_) {
      return false;
    }
  }

  // ============ Speed Test ============

  Future<void> saveSpeedTest(SpeedTestData data) async {
    if (_box == null || data.isEmpty) return;
    try {
      await _box!.put(_speedKey, jsonEncode(data.toJson()));
      await _box!.put(_speedTimestampKey, DateTime.now().millisecondsSinceEpoch.toString());
    } catch (_) {}
  }

  Future<SpeedTestData?> loadSpeedTest() async {
    if (_box == null) return null;
    try {
      final jsonStr = _box!.get(_speedKey);
      if (jsonStr == null) return null;
      return SpeedTestData.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  bool isSpeedCacheValid() {
    if (_box == null) return false;
    try {
      final timestampStr = _box!.get(_speedTimestampKey);
      if (timestampStr == null) return false;
      final timestamp = int.tryParse(timestampStr) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      return age < _cacheValidityMinutes * 60 * 1000;
    } catch (_) {
      return false;
    }
  }

  // ============ Standee Info ============

  Future<void> saveStandeeInfo(StandeeInfo info) async {
    if (_box == null || info.isEmpty) return;
    try {
      await _box!.put(_standeeKey, jsonEncode(info.toJson()));
      await _box!.put(_standeeTimestampKey, DateTime.now().millisecondsSinceEpoch.toString());
    } catch (_) {}
  }

  Future<StandeeInfo?> loadStandeeInfo() async {
    if (_box == null) return null;
    try {
      final jsonStr = _box!.get(_standeeKey);
      if (jsonStr == null) return null;
      return StandeeInfo.fromJson(jsonDecode(jsonStr));
    } catch (_) {
      return null;
    }
  }

  bool isStandeeCacheValid() {
    if (_box == null) return false;
    try {
      final timestampStr = _box!.get(_standeeTimestampKey);
      if (timestampStr == null) return false;
      final timestamp = int.tryParse(timestampStr) ?? 0;
      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      return age < 60 * 60 * 1000; // 1 hour
    } catch (_) {
      return false;
    }
  }

  Future<void> clear() async {
    try {
      await _box?.clear();
    } catch (_) {}
  }
}
