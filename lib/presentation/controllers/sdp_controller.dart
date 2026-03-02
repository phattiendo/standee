import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/network/socket_client.dart';
import '../../data/datasources/sdp_datasource.dart';
import '../../data/models/air_quality_model.dart';
import '../../data/models/speed_test_model.dart';
import '../../data/models/standee_info_model.dart';
import '../../data/models/weather_model.dart';

/// Controller quản lý state của SDP (Special Dynamic Poster)
class SdpController {
  SdpController({
    SdpDataSource? dataSource,
    this.onDataChanged,
  }) : _dataSource = dataSource ?? SdpDataSource();

  final SdpDataSource _dataSource;
  final void Function(SdpData data)? onDataChanged;

  StreamSubscription<WeatherData>? _weatherSub;

  WeatherData _weather = WeatherData.empty();
  AirQualityData _airQuality = AirQualityData.empty();
  SpeedTestData _speedTest = SpeedTestData.empty();
  StandeeInfo _standeeInfo = StandeeInfo.empty();
  String? _posterUrl;

  WeatherData get weather => _weather;
  AirQualityData get airQuality => _airQuality;
  SpeedTestData get speedTest => _speedTest;
  StandeeInfo get standeeInfo => _standeeInfo;
  String? get posterUrl => _posterUrl;

  bool _isLoading = false;
  bool get isLoading => _isLoading;
  bool _initialized = false;
  bool _initializing = false;

  /// Khởi tạo và bắt đầu lắng nghe data
  Future<void> init({String? posterUrl}) async {
    if (_initialized || _initializing) return;
    _initializing = true;

    _posterUrl = posterUrl;
    debugPrint('SdpController: init started');

    try {
      // 1. Init datasource
      await _dataSource.init().timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('SdpController: datasource init timeout');
        },
      );

      // 2. Load data từ cache
      try {
        final cached = await _dataSource.loadAllFromCache().timeout(
          const Duration(seconds: 2),
        );
        _airQuality = cached.airQuality;
        _speedTest = cached.speedTest;
        _standeeInfo = cached.standeeInfo;
        debugPrint('SdpController: loaded data from cache');
      } catch (_) {}

      // 3. Weather via WebSocket
      unawaited(WeatherSocketClient.I.init());
      _weatherSub = WeatherSocketClient.I.weatherStream.listen(_onWeatherData);
      final cachedWeather = WeatherSocketClient.I.lastWeatherData;
      if (cachedWeather != null) {
        _weather = cachedWeather;
      }

      _initialized = true;
      _notifyChanged();

      // 4. Fetch từ API background
      unawaited(_fetchFromApi());

      debugPrint('SdpController: init completed');
    } catch (e) {
      debugPrint('SdpController init error: $e');
      _initialized = true;
      _notifyChanged();
    } finally {
      _initializing = false;
    }
  }

  void _onWeatherData(WeatherData data) {
    _weather = data;
    _notifyChanged();
  }

  Future<void> _fetchFromApi() async {
    _isLoading = true;
    _notifyChanged();

    try {
      final result = await _dataSource.fetchAll().timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('SdpController: API fetch timeout');
          return SdpFetchResult(
            airQuality: _airQuality,
            speedTest: _speedTest,
            standeeInfo: _standeeInfo,
          );
        },
      );
      _airQuality = result.airQuality;
      _speedTest = result.speedTest;
      _standeeInfo = result.standeeInfo;
    } catch (e) {
      debugPrint('SdpController fetch error: $e');
    }

    _isLoading = false;
    _notifyChanged();
  }

  Future<void> refresh() async {
    await _fetchFromApi();
  }

  Future<void> preload({String? posterUrl}) async {
    _posterUrl = posterUrl;

    try {
      await _dataSource.init().timeout(const Duration(seconds: 2));

      final cached = await _dataSource.loadAllFromCache().timeout(
        const Duration(seconds: 2),
      );
      _airQuality = cached.airQuality;
      _speedTest = cached.speedTest;
      _standeeInfo = cached.standeeInfo;

      unawaited(WeatherSocketClient.I.init());
      final cachedWeather = WeatherSocketClient.I.lastWeatherData;
      if (cachedWeather != null) {
        _weather = cachedWeather;
      }

      _notifyChanged();
      unawaited(_fetchFromApi());
    } catch (e) {
      debugPrint('SdpController preload error: $e');
    }
  }

  void _notifyChanged() {
    onDataChanged?.call(SdpData(
      weather: _weather,
      airQuality: _airQuality,
      speedTest: _speedTest,
      standeeInfo: _standeeInfo,
      posterUrl: _posterUrl,
      isLoading: _isLoading,
    ));
  }

  void setPosterUrl(String? url) {
    _posterUrl = url;
    _notifyChanged();
  }

  void dispose() {
    _weatherSub?.cancel();
  }
}

/// Data class chứa tất cả dữ liệu SDP
class SdpData {
  final WeatherData weather;
  final AirQualityData airQuality;
  final SpeedTestData speedTest;
  final StandeeInfo standeeInfo;
  final String? posterUrl;
  final bool isLoading;

  const SdpData({
    required this.weather,
    required this.airQuality,
    required this.speedTest,
    required this.standeeInfo,
    this.posterUrl,
    this.isLoading = false,
  });

  factory SdpData.empty() => SdpData(
        weather: WeatherData.empty(),
        airQuality: AirQualityData.empty(),
        speedTest: SpeedTestData.empty(),
        standeeInfo: StandeeInfo.empty(),
      );
}
