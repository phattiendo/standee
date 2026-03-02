  import 'package:intl/intl.dart';

class SpeedTestData {
  final int id;
  final double downloadSpeed; // Mbps
  final double uploadSpeed; // Mbps
  final int ping; // ms
  final DateTime? timestamp;

  const SpeedTestData({
    required this.id,
    required this.downloadSpeed,
    required this.uploadSpeed,
    required this.ping,
    this.timestamp,
  });

  factory SpeedTestData.fromJson(Map<String, dynamic> json) {
    return SpeedTestData(
      id: _parseInt(json['id'] ?? 0),
      downloadSpeed: _parseDouble(json['downloadSpeed'] ?? json['download'] ?? 0),
      uploadSpeed: _parseDouble(json['uploadSpeed'] ?? json['upload'] ?? 0),
      ping: _parseInt(json['ping'] ?? json['latency'] ?? 0),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'downloadSpeed': downloadSpeed,
        'uploadSpeed': uploadSpeed,
        'ping': ping,
        'timestamp': timestamp?.toIso8601String(),
      };

  factory SpeedTestData.empty() => const SpeedTestData(
        id: 0,
        downloadSpeed: 0,
        uploadSpeed: 0,
        ping: 0,
      );

  bool get isEmpty => downloadSpeed == 0 && uploadSpeed == 0;

  /// Parse list và lấy item mới nhất theo timestamp
  static SpeedTestData? getLatestFromList(List<dynamic> list) {
    if (list.isEmpty) return null;

    final items = list
        .whereType<Map<String, dynamic>>()
        .map(SpeedTestData.fromJson)
        .toList();

    if (items.isEmpty) return null;

    // Sort theo timestamp giảm dần và lấy item đầu tiên (mới nhất)
    items.sort((a, b) {
      final aTime = a.timestamp ?? DateTime(1970);
      final bTime = b.timestamp ?? DateTime(1970);
      return bTime.compareTo(aTime);
    });

    return items.first;
  }

  /// Format thời gian cập nhật
  String get formattedUpdateTime {
    if (timestamp == null) return '--:-- PM';
    return DateFormat('h:mm a').format(timestamp!);
  }
}

// Helper functions
double _parseDouble(dynamic value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

int _parseInt(dynamic value) {
  if (value is int) return value;
  if (value is double) return value.round();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}
