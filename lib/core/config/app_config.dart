/// Cấu hình app - bật/tắt mock mode để test offline
class AppConfig {
  AppConfig._();

  /// Bật mock mode = true để dùng data giả từ assets/mock/
  /// Tắt mock mode = false để dùng API thật
  static const bool useMockData = true;

  /// Đường dẫn file mock data
  static const String mockDataPath = 'assets/mock/mock_data.json';

  /// API Base URL (khi không dùng mock)
  static const String apiBaseUrl = 'http://10.10.115.20:9094';

  /// WebSocket URL cho Weather
  static const String weatherWsUrl = 'http://10.10.115.20:9094/ws';
}
