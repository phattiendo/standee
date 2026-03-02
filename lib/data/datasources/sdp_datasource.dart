import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/air_quality_model.dart';
import '../models/speed_test_model.dart';
import '../models/standee_info_model.dart';
import 'sdp_cache.dart';

/// DataSource để fetch dữ liệu cho SDP với cache
class SdpDataSource {
  SdpDataSource({Dio? dio}) : _dio = dio ?? DioClient.I.client;

  final Dio _dio;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await SdpCache.I.init();
    _initialized = true;
  }

  /// Fetch Air Quality
  Future<AirQualityData> fetchAirQuality({bool forceRefresh = false}) async {
    if (!forceRefresh && SdpCache.I.isAqiCacheValid()) {
      final cached = await SdpCache.I.loadAirQuality();
      if (cached != null && !cached.isEmpty) {
        return cached;
      }
    }

    try {
      final response = await _dio.get(
        ApiConstants.airQualityPath,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        final aqi = AirQualityData.fromJson(data);
        if (!aqi.isEmpty) {
          unawaited(SdpCache.I.saveAirQuality(aqi));
        }
        return aqi;
      }
      return await _loadAqiCacheOrEmpty();
    } catch (e) {
      debugPrint('fetchAirQuality error: $e');
      return await _loadAqiCacheOrEmpty();
    }
  }

  Future<AirQualityData> _loadAqiCacheOrEmpty() async {
    final cached = await SdpCache.I.loadAirQuality();
    return cached ?? AirQualityData.empty();
  }

  /// Fetch Speed Test
  Future<SpeedTestData> fetchSpeedTest({bool forceRefresh = false}) async {
    if (!forceRefresh && SdpCache.I.isSpeedCacheValid()) {
      final cached = await SdpCache.I.loadSpeedTest();
      if (cached != null && !cached.isEmpty) {
        return cached;
      }
    }

    try {
      final response = await _dio.get(
        ApiConstants.speedTestPath,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final data = response.data;

      List<dynamic> list = [];
      if (data is Map<String, dynamic>) {
        final result = data['result'];
        if (result is List) {
          list = result;
        }
      } else if (data is List) {
        list = data;
      }

      final latest = SpeedTestData.getLatestFromList(list);
      if (latest != null && !latest.isEmpty) {
        unawaited(SdpCache.I.saveSpeedTest(latest));
        return latest;
      }
      return await _loadSpeedCacheOrEmpty();
    } catch (e) {
      debugPrint('fetchSpeedTest error: $e');
      return await _loadSpeedCacheOrEmpty();
    }
  }

  Future<SpeedTestData> _loadSpeedCacheOrEmpty() async {
    final cached = await SdpCache.I.loadSpeedTest();
    return cached ?? SpeedTestData.empty();
  }

  /// Fetch Standee Info
  Future<StandeeInfo> fetchStandeeInfo({bool forceRefresh = false}) async {
    if (!forceRefresh && SdpCache.I.isStandeeCacheValid()) {
      final cached = await SdpCache.I.loadStandeeInfo();
      if (cached != null && !cached.isEmpty) {
        return cached;
      }
    }

    try {
      final response = await _dio.get(
        ApiConstants.standeeInfoPath,
        options: Options(receiveTimeout: const Duration(seconds: 5)),
      );
      final data = response.data;

      StandeeInfo? info;

      if (data is Map<String, dynamic>) {
        if (data.containsKey('standeeId')) {
          info = StandeeInfo.fromJson(data);
        } else if (data['result'] is Map<String, dynamic>) {
          info = StandeeInfo.fromJson(data['result']);
        }
      }

      if (info != null && !info.isEmpty) {
        unawaited(SdpCache.I.saveStandeeInfo(info));
        return info;
      }
      return await _loadStandeeCacheOrEmpty();
    } catch (e) {
      debugPrint('fetchStandeeInfo error: $e');
      return await _loadStandeeCacheOrEmpty();
    }
  }

  Future<StandeeInfo> _loadStandeeCacheOrEmpty() async {
    final cached = await SdpCache.I.loadStandeeInfo();
    return cached ?? StandeeInfo.empty();
  }

  /// Fetch tất cả data song song
  Future<SdpFetchResult> fetchAll({bool forceRefresh = false}) async {
    final results = await Future.wait([
      fetchAirQuality(forceRefresh: forceRefresh),
      fetchSpeedTest(forceRefresh: forceRefresh),
      fetchStandeeInfo(forceRefresh: forceRefresh),
    ]);

    return SdpFetchResult(
      airQuality: results[0] as AirQualityData,
      speedTest: results[1] as SpeedTestData,
      standeeInfo: results[2] as StandeeInfo,
    );
  }

  /// Load tất cả từ cache
  Future<SdpFetchResult> loadAllFromCache() async {
    if (!_initialized) await init();

    final results = await Future.wait([
      SdpCache.I.loadAirQuality(),
      SdpCache.I.loadSpeedTest(),
      SdpCache.I.loadStandeeInfo(),
    ]);

    return SdpFetchResult(
      airQuality: results[0] as AirQualityData? ?? AirQualityData.empty(),
      speedTest: results[1] as SpeedTestData? ?? SpeedTestData.empty(),
      standeeInfo: results[2] as StandeeInfo? ?? StandeeInfo.empty(),
    );
  }
}

/// Kết quả fetch SDP data
class SdpFetchResult {
  final AirQualityData airQuality;
  final SpeedTestData speedTest;
  final StandeeInfo standeeInfo;

  const SdpFetchResult({
    required this.airQuality,
    required this.speedTest,
    required this.standeeInfo,
  });
}
