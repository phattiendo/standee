
class WeatherData {
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double uvIndex;
  final double highTemp;
  final double lowTemp;
  final int weatherCode;
  final String condition;
  final List<HourlyForecast> hourlyForecast;
  final DateTime? updatedAt;

  const WeatherData({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.uvIndex,
    required this.highTemp,
    required this.lowTemp,
    required this.weatherCode,
    required this.condition,
    required this.hourlyForecast,
    this.updatedAt,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    // Parse nested structure from STOMP message
    final current = json['current'] as Map<String, dynamic>? ?? {};
    final daily = json['daily'] as Map<String, dynamic>? ?? {};
    final hourly = json['hourly'] as Map<String, dynamic>? ?? {};

    // Parse temperature
    final temp = _parseDouble(
      current['temperature'] ?? json['temperature'] ?? json['temp'] ?? 0,
    );

    // Parse humidity
    final humidity = _parseInt(
      current['humidity'] ?? json['humidity'] ?? 0,
    );

    // Parse UV index
    final uvIndex = _parseDouble(
      current['uv_index'] ?? current['uvIndex'] ?? json['uv_index'] ?? json['uvIndex'] ?? 0,
    );

    // Parse weather code
    final weatherCode = _parseInt(
      current['weatherCode'] ?? current['weather_code'] ?? json['weatherCode'] ?? 0,
    );

    // Parse high/low temps from daily
    final highTemp = _parseDouble(
      daily['temperature_2m_max'] ?? json['highTemp'] ?? json['temp_max'] ?? temp + 2,
    );
    final lowTemp = _parseDouble(
      daily['temperature_2m_min'] ?? json['lowTemp'] ?? json['temp_min'] ?? temp - 2,
    );

    // Parse hourly forecast
    List<HourlyForecast> hourlyList = [];
    final times = hourly['time'] as List<dynamic>? ?? [];
    final temps = hourly['temperature_2m'] as List<dynamic>? ?? [];
    final codes = hourly['weather_code'] as List<dynamic>? ?? [];

    if (times.isNotEmpty && temps.isNotEmpty) {
      // Tìm index của giờ hiện tại
      final now = DateTime.now();
      int startIndex = 0;
      for (int i = 0; i < times.length; i++) {
        final dt = DateTime.tryParse(times[i].toString());
        if (dt != null && dt.isAfter(now)) {
          startIndex = i;
          break;
        }
      }

      // Lấy 8 giờ tiếp theo từ giờ hiện tại
      for (int i = startIndex; i < times.length && hourlyList.length < 8; i++) {
        final timeStr = times[i].toString();
        final tempVal = _parseDouble(temps[i]);
        final code = i < codes.length ? _parseInt(codes[i]) : 0;

        hourlyList.add(HourlyForecast(
          time: _formatHourlyTime(timeStr),
          temperature: tempVal,
          weatherCode: code,
          condition: _weatherCodeToCondition(code),
        ));
      }
    }

    // Parse time
    DateTime? updatedAt;
    final timeStr = current['time']?.toString() ?? json['time']?.toString();
    if (timeStr != null) {
      updatedAt = DateTime.tryParse(timeStr);
    }

    return WeatherData(
      temperature: temp,
      feelsLike: temp, // API không có feels_like, dùng temp
      humidity: humidity,
      uvIndex: uvIndex,
      highTemp: highTemp,
      lowTemp: lowTemp,
      weatherCode: weatherCode,
      condition: _weatherCodeToCondition(weatherCode),
      hourlyForecast: hourlyList,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'current': {
      'temperature': temperature,
      'humidity': humidity,
      'weatherCode': weatherCode,
      'uv_index': uvIndex,
      'time': updatedAt?.toIso8601String(),
    },
    'daily': {
      'temperature_2m_max': highTemp,
      'temperature_2m_min': lowTemp,
    },
    'hourly': {
      'time': hourlyForecast.map((e) => e.time).toList(),
      'temperature_2m': hourlyForecast.map((e) => e.temperature).toList(),
      'weather_code': hourlyForecast.map((e) => e.weatherCode).toList(),
    },
  };

  factory WeatherData.empty() => const WeatherData(
    temperature: 0,
    feelsLike: 0,
    humidity: 0,
    uvIndex: 0,
    highTemp: 0,
    lowTemp: 0,
    weatherCode: 0,
    condition: 'unknown',
    hourlyForecast: [],
  );

  bool get isEmpty => temperature == 0 && humidity == 0;

  /// Format UV index thành text
  String get uvDescription {
    if (uvIndex <= 2) return 'Low';
    if (uvIndex <= 5) return 'Moderate';
    if (uvIndex <= 7) return 'High';
    if (uvIndex <= 10) return 'Very High';
    return 'Extreme';
  }
}

/// Dự báo theo giờ
class HourlyForecast {
  final String time;
  final double temperature;
  final int weatherCode;
  final String condition;

  const HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    required this.condition,
  });

  factory HourlyForecast.fromJson(Map<String, dynamic> json) {
    final code = _parseInt(json['weatherCode'] ?? json['weather_code'] ?? 0);
    return HourlyForecast(
      time: _formatHourlyTime(json['time']?.toString() ?? ''),
      temperature: _parseDouble(json['temperature'] ?? json['temp'] ?? 0),
      weatherCode: code,
      condition: _weatherCodeToCondition(code),
    );
  }

  Map<String, dynamic> toJson() => {
    'time': time,
    'temperature': temperature,
    'weatherCode': weatherCode,
    'condition': condition,
  };
}

// ============ Helper Functions ============

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

/// Format "2026-02-26T09:00" → "9:00"
String _formatHourlyTime(String isoTime) {
  if (isoTime.isEmpty) return '';
  
  final dt = DateTime.tryParse(isoTime);
  if (dt == null) return isoTime;
  
  final hour = dt.hour;
  final minute = dt.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

/// Convert WMO Weather Code to condition string
/// https://open-meteo.com/en/docs (Weather Interpretation Codes)
String _weatherCodeToCondition(int code) {
  switch (code) {
    case 0:
      return 'sunny'; // Clear sky
    case 1:
    case 2:
    case 3:
      return 'cloudy'; // Mainly clear, partly cloudy, overcast
    case 45:
    case 48:
      return 'foggy'; // Fog
    case 51:
    case 53:
    case 55:
      return 'drizzle'; // Drizzle
    case 56:
    case 57:
      return 'freezing_drizzle';
    case 61:
    case 63:
    case 65:
      return 'rainy'; // Rain
    case 66:
    case 67:
      return 'freezing_rain';
    case 71:
    case 73:
    case 75:
      return 'snowy'; // Snow fall
    case 77:
      return 'snow_grains';
    case 80:
    case 81:
    case 82:
      return 'rainy'; // Rain showers
    case 85:
    case 86:
      return 'snowy'; // Snow showers
    case 95:
      return 'thunderstorm';
    case 96:
    case 99:
      return 'thunderstorm_hail';
    default:
      return 'cloudy';
  }
}

/// Get weather icon based on condition
String getWeatherIcon(String condition) {
  switch (condition) {
    case 'sunny':
      return '☀️';
    case 'cloudy':
      return '☁️';
    case 'rainy':
    case 'drizzle':
      return '🌧️';
    case 'thunderstorm':
    case 'thunderstorm_hail':
      return '⛈️';
    case 'snowy':
    case 'snow_grains':
      return '❄️';
    case 'foggy':
      return '🌫️';
    default:
      return '🌤️';
  }
}
