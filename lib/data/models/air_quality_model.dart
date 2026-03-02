class AirQualityData {
  final DateTime? time;
  final double pm25;
  final double pm10;
  final double sulphurDioxide; // SO2
  final double nitrogenDioxide; // NO2
  final double ozone; // O3
  final double carbonMonoxide; // CO
  final int usAqi; // US Air Quality Index (CAQI)

  const AirQualityData({
    this.time,
    required this.pm25,
    required this.pm10,
    required this.sulphurDioxide,
    required this.nitrogenDioxide,
    required this.ozone,
    required this.carbonMonoxide,
    required this.usAqi,
  });

  factory AirQualityData.fromJson(Map<String, dynamic> json) {
    // Handle nested response: { "code": 200, "result": {...} }
    final data = json['result'] as Map<String, dynamic>? ?? json;

    return AirQualityData(
      time: DateTime.tryParse(data['time']?.toString() ?? ''),
      pm25: _parseDouble(data['pm2_5'] ?? data['pm25'] ?? 0),
      pm10: _parseDouble(data['pm10'] ?? 0),
      sulphurDioxide: _parseDouble(data['sulphur_dioxide'] ?? data['so2'] ?? 0),
      nitrogenDioxide: _parseDouble(data['nitrogen_dioxide'] ?? data['no2'] ?? 0),
      ozone: _parseDouble(data['ozone'] ?? data['o3'] ?? 0),
      carbonMonoxide: _parseDouble(data['carbon_monoxide'] ?? data['co'] ?? 0),
      usAqi: _parseInt(data['us_aqi'] ?? data['aqi'] ?? data['caqi'] ?? 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'time': time?.toIso8601String(),
        'pm2_5': pm25,
        'pm10': pm10,
        'sulphur_dioxide': sulphurDioxide,
        'nitrogen_dioxide': nitrogenDioxide,
        'ozone': ozone,
        'carbon_monoxide': carbonMonoxide,
        'us_aqi': usAqi,
      };

  factory AirQualityData.empty() => const AirQualityData(
        pm25: 0,
        pm10: 0,
        sulphurDioxide: 0,
        nitrogenDioxide: 0,
        ozone: 0,
        carbonMonoxide: 0,
        usAqi: 0,
      );

  bool get isEmpty => usAqi == 0;

  /// Lấy mô tả chất lượng không khí dựa trên US AQI
  String get qualityDescription {
    if (usAqi <= 50) return 'Tốt';
    if (usAqi <= 100) return 'Trung bình';
    if (usAqi <= 150) return 'Không tốt cho nhóm nhạy cảm';
    if (usAqi <= 200) return 'Không lành mạnh';
    if (usAqi <= 300) return 'Rất không lành mạnh';
    return 'Nguy hiểm';
  }


  String get qualityColorHex {
    if (usAqi <= 50) return '#00E400'; // Good - Green
    if (usAqi <= 100) return '#FFFF00'; // Moderate - Yellow
    if (usAqi <= 150) return '#FF7E00'; // Unhealthy for Sensitive - Orange
    if (usAqi <= 200) return '#FF0000'; // Unhealthy - Red
    if (usAqi <= 300) return '#8F3F97'; // Very Unhealthy - Purple
    return '#7E0023'; // Hazardous - Maroon
  }

  double get estimatedO2 => 317; // Giá trị mẫu như trong hình

  /// CO2 ước tính (ppm)
  double get estimatedCo2 => carbonMonoxide > 0 ? carbonMonoxide / 2 : 124;

  /// Dust (bụi) - lấy từ PM2.5 + PM10
  double get dust => pm25 + pm10;
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
