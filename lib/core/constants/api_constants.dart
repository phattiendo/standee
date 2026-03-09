/// API endpoints & constants for slideshow
abstract final class ApiConstants {
  /// Base URL của server standee
  static const String baseUrl = 'http://10.10.115.20:9094';

  /// WebSocket base URL
  static const String wsBaseUrl = 'ws://10.10.115.20:9094';

  /// Standee ID dùng cho playlist API
  static const String standeeId = '7bbb9af3-95a7-42af-8805-6023e60a3bdc';

  /// Relative path của API playlist
  static String get playlistPath =>
      '/api/poster/$standeeId/withActivePosters';

  /// Full URL (nếu cần debug)
  static String get playlistUrl => '$baseUrl$playlistPath';

  /// API version (game-update style: check version → download if changed).
  static const String versionPath = '/api/standee/version';
  static String get versionUrl => '$baseUrl$versionPath';

  // ============ SDP (Special Dynamic Poster) APIs ============

  /// WebSocket endpoint cho Weather realtime
  static const String weatherWsPath = '/ws/topic/weather';
  static String get weatherWsUrl => '$wsBaseUrl$weatherWsPath';

  /// REST API cho Air Quality
  static const String airQualityPath = '/api/weather/air-quality';
  static String get airQualityUrl => '$baseUrl$airQualityPath';

  /// REST API cho Speed Test
  static const String speedTestPath = '/api/speedtest/all';
  static String get speedTestUrl => '$baseUrl$speedTestPath';

  /// REST API cho Standee Info
  static const String standeeInfoPath = '/api/standee';
  static String get standeeInfoUrl => '$baseUrl$standeeInfoPath';

  // ============ SDP Configuration ============

  /// Duration mặc định của SDP (giây) - sẽ được override bởi API displayDuration
  static const int sdpDurationSeconds = 40;

  /// Asset path cho SDP background
  /// - tetve.jpg: Theme sáng (Tết vè) - phù hợp ban ngày
  /// - tetden.jpg: Theme tối - phù hợp ban đêm
  static const String sdpBackgroundLight = 'assets/tetve.jpg';
  static const String sdpBackgroundDark = 'assets/tetden.jpg';

  /// Background mặc định cho SDP (Tết vè)
  static const String sdpDefaultBackground = sdpBackgroundLight;
}

