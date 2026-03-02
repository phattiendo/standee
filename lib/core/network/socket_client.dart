import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../../data/datasources/weather_cache.dart';
import '../../data/models/weather_model.dart';
import '../constants/api_constants.dart';

/// WebSocket client cho Weather realtime data sử dụng STOMP over SockJS.
class WeatherSocketClient {
  WeatherSocketClient._internal();

  static final WeatherSocketClient _instance = WeatherSocketClient._internal();
  static WeatherSocketClient get I => _instance;

  StompClient? _stompClient;

  final StreamController<WeatherData> _weatherController =
      StreamController<WeatherData>.broadcast();

  Stream<WeatherData> get weatherStream => _weatherController.stream;

  WeatherData? _lastWeatherData;
  WeatherData? get lastWeatherData => _lastWeatherData;

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _initialized = false;
  bool _initializing = false;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;

  /// Khởi tạo: load cache trước, sau đó connect STOMP
  Future<void> init() async {
    if (_initialized || _initializing) return;
    _initializing = true;

    try {
      // 1. Init và load cache với timeout
      await WeatherCache.I.init();
      final cached = await WeatherCache.I.loadWeather();
      if (cached != null && !cached.isEmpty) {
        _lastWeatherData = cached;
        _weatherController.add(cached);
        debugPrint('WeatherSocketClient: loaded from cache');
      }

      _initialized = true;

      // 2. Connect STOMP (không await)
      _connect();
    } catch (e) {
      debugPrint('WeatherSocketClient init error: $e');
      _initialized = true; // Vẫn đánh dấu initialized để không retry liên tục
    } finally {
      _initializing = false;
    }
  }

  void _connect() {
    if (_isConnected || _stompClient != null) return;

    try {
      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: '${ApiConstants.baseUrl}/ws',
          onConnect: _onConnect,
          onDisconnect: _onDisconnect,
          onStompError: _onError,
          onWebSocketError: _onError,
          reconnectDelay: Duration(seconds: _getReconnectDelay()),
          connectionTimeout: const Duration(seconds: 10),
        ),
      );

      _stompClient!.activate();
      debugPrint('WeatherSocketClient: connecting...');
    } catch (e) {
      debugPrint('WeatherSocketClient connect error: $e');
    }
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    _reconnectAttempts = 0;
    debugPrint('WeatherSocketClient: connected');

    _stompClient!.subscribe(
      destination: '/topic/weather',
      callback: _onMessage,
    );
  }

  void _onMessage(StompFrame frame) {
    if (frame.body == null) return;

    try {
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      final weather = WeatherData.fromJson(json);

      _lastWeatherData = weather;
      _weatherController.add(weather);

      // Save to cache (không await)
      WeatherCache.I.saveWeather(weather);
      debugPrint('WeatherSocketClient: received weather update');
    } catch (e) {
      debugPrint('WeatherSocketClient parse error: $e');
    }
  }

  void _onDisconnect(StompFrame frame) {
    _isConnected = false;
    debugPrint('WeatherSocketClient: disconnected');
    _scheduleReconnect();
  }

  void _onError(dynamic error) {
    _isConnected = false;
    debugPrint('WeatherSocketClient error: $error');
    _scheduleReconnect();
  }

  int _getReconnectDelay() {
    return (1 << _reconnectAttempts).clamp(1, 60);
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
  }

  void disconnect() {
    try {
      _stompClient?.deactivate();
    } catch (_) {}
    _stompClient = null;
    _isConnected = false;
    _reconnectAttempts = 0;
  }

  void dispose() {
    disconnect();
    _weatherController.close();
  }
}
