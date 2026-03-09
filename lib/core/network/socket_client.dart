import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';

import '../connectivity/connectivity_service.dart';
import '../../data/datasources/weather_cache.dart';
import '../../data/models/weather_model.dart';
import '../constants/api_constants.dart';

/// WebSocket client cho Weather realtime. Chỉ connect khi có mạng; mất mạng thì ngưng, không gọi hoài.
class WeatherSocketClient {
  WeatherSocketClient._internal();

  static final WeatherSocketClient _instance = WeatherSocketClient._internal();
  static WeatherSocketClient get I => _instance;

  StompClient? _stompClient;
  Timer? _reconnectTimer;
  StreamSubscription<bool>? _connectivitySub;

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

  /// Khởi tạo: load cache trước; chỉ connect STOMP khi có mạng; nghe connectivity để ngưng khi mất mạng.
  Future<void> init() async {
    if (_initialized || _initializing) return;
    _initializing = true;

    debugPrint('🌤️ WeatherSocket: init started');

    try {
      await WeatherCache.I.init();
      final cached = await WeatherCache.I.loadWeather();
      if (cached != null && !cached.isEmpty) {
        _lastWeatherData = cached;
        _weatherController.add(cached);
        debugPrint('🌤️ WeatherSocket: loaded from cache - ${cached.temperature}°C');
      }

      await ConnectivityService.I.init();
      _connectivitySub = ConnectivityService.I.onStatusChanged.listen((online) {
        if (online) {
          _reconnectAttempts = 0;
          _connect();
        } else {
          _reconnectTimer?.cancel();
          disconnect();
          debugPrint('🌤️ WeatherSocket: mất mạng → ngưng, dùng data ROM');
        }
      });

      _initialized = true;

      // Chỉ connect nếu đang có mạng (khi mất mạng listener sẽ gọi disconnect)
      if (await ConnectivityService.I.isOnline) _connect();
    } catch (e) {
      debugPrint('🌤️ WeatherSocket init error: $e');
      _initialized = true;
    } finally {
      _initializing = false;
    }
  }

  void _connect() {
    if (_isConnected) {
      debugPrint('🌤️ WeatherSocket: already connected');
      return;
    }
    
    // Cancel existing client
    try {
      _stompClient?.deactivate();
    } catch (_) {}
    _stompClient = null;

    final wsUrl = '${ApiConstants.baseUrl}/ws';
    debugPrint('🌤️ WeatherSocket: connecting to $wsUrl');

    try {
      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: wsUrl,
          onConnect: _onConnect,
          onDisconnect: _onDisconnect,
          onStompError: _onStompError,
          onWebSocketError: _onWebSocketError,
          onDebugMessage: _onDebugMessage,
          reconnectDelay: const Duration(seconds: 5),
          connectionTimeout: const Duration(seconds: 20),
          heartbeatIncoming: const Duration(milliseconds: 10000),
          heartbeatOutgoing: const Duration(milliseconds: 10000),
        ),
      );

      _stompClient!.activate();
      debugPrint('🌤️ WeatherSocket: activate() called, waiting for STOMP CONNECTED...');
    } catch (e) {
      debugPrint('🌤️ WeatherSocket connect error: $e');
      _scheduleReconnect();
    }
  }

  void _onDebugMessage(String msg) {
    // Filter heartbeat spam
    if (msg == '<<< h' || msg == '>>> h') return;
    debugPrint('🌤️ STOMP: $msg');
  }

  void _onConnect(StompFrame frame) {
    _isConnected = true;
    _reconnectAttempts = 0;
    debugPrint('🌤️ WeatherSocket: ✅ STOMP CONNECTED!');

    try {
      // Subscribe to weather topic
      _stompClient!.subscribe(
        destination: '/topic/weather',
        callback: _onMessage,
      );
      debugPrint('🌤️ WeatherSocket: ✅ subscribed to /topic/weather');
    } catch (e) {
      debugPrint('🌤️ WeatherSocket subscribe error: $e');
    }
  }

  void _onMessage(StompFrame frame) {
    debugPrint('🌤️ WeatherSocket: 📨 MESSAGE RECEIVED!');
    
    if (frame.body == null || frame.body!.isEmpty) {
      debugPrint('🌤️ WeatherSocket: message body is empty');
      return;
    }

    debugPrint('🌤️ WeatherSocket: body length = ${frame.body!.length}');
    debugPrint('🌤️ WeatherSocket: body preview = ${frame.body!.substring(0, frame.body!.length.clamp(0, 300))}');

    try {
      final json = jsonDecode(frame.body!) as Map<String, dynamic>;
      final weather = WeatherData.fromJson(json);

      if (!weather.isEmpty) {
        _lastWeatherData = weather;
        _weatherController.add(weather);
        
        // Save to cache
        unawaited(WeatherCache.I.saveWeather(weather));
        debugPrint('🌤️ WeatherSocket: ✅ weather updated - ${weather.temperature}°C, ${weather.condition}');
      } else {
        debugPrint('🌤️ WeatherSocket: parsed weather is empty');
      }
    } catch (e) {
      debugPrint('🌤️ WeatherSocket parse error: $e');
    }
  }

  void _onDisconnect(StompFrame frame) {
    _isConnected = false;
    debugPrint('🌤️ WeatherSocket: ❌ DISCONNECTED');
    _scheduleReconnect();
  }

  void _onStompError(StompFrame frame) {
    _isConnected = false;
    debugPrint('🌤️ WeatherSocket: ❌ STOMP ERROR: ${frame.body}');
    _scheduleReconnect();
  }

  void _onWebSocketError(dynamic error) {
    _isConnected = false;
    debugPrint('🌤️ WeatherSocket: ❌ WebSocket ERROR: $error');
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('🌤️ WeatherSocket: max reconnect attempts reached, thôi không thử nữa');
      return;
    }
    _reconnectAttempts++;
    final delay = Duration(seconds: (2 * _reconnectAttempts).clamp(2, 30));
    debugPrint('🌤️ WeatherSocket: thử lại sau ${delay.inSeconds}s (lần $_reconnectAttempts)');
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, () async {
      if (_isConnected) return;
      if (!await ConnectivityService.I.isOnline) return;
      _connect();
    });
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    try {
      _stompClient?.deactivate();
    } catch (_) {}
    _stompClient = null;
    _isConnected = false;
  }

  /// Gọi tay khi muốn thử kết nối lại (vd từ UI).
  void reconnect() {
    _reconnectAttempts = 0;
    disconnect();
    _connect();
  }

  void dispose() {
    _connectivitySub?.cancel();
    disconnect();
    _reconnectAttempts = 0;
    _weatherController.close();
  }
}
