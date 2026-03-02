import 'package:flutter/material.dart';

import '../../../data/models/weather_model.dart';

/// Section hiển thị lời khuyên sức khỏe dựa trên thời tiết với scale support
class HealthAdviceSection extends StatelessWidget {
  final WeatherData weather;
  final double scale;

  const HealthAdviceSection({
    super.key,
    required this.weather,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final advices = _getHealthAdvices(weather);

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: advices.map((advice) {
            return Padding(
              padding: EdgeInsets.only(bottom: 14 * scale),
              child: Text(
                advice,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20 * scale,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  /// Lấy danh sách lời khuyên dựa trên nhiệt độ và điều kiện thời tiết
  List<String> _getHealthAdvices(WeatherData weather) {
    final List<String> advices = [];
    final temp = weather.temperature;
    final humidity = weather.humidity;
    final uvIndex = weather.uvIndex;

    // Lời khuyên về nhiệt độ và độ ẩm
    advices.add(
      'Nhiệt độ ${temp.round()}°C, độ ẩm $humidity%:\n'
      '${_getTemperatureAdvice(temp, humidity)}',
    );

    // Lời khuyên về UV
    if (uvIndex > 0) {
      advices.add(
        'Tia UV mức ${uvIndex.toStringAsFixed(1)}:\n'
        '${_getUvAdvice(uvIndex.round())}',
      );
    }

    // Lời khuyên chung
    advices.add(_getGeneralAdvice(temp));

    return advices;
  }

  String _getTemperatureAdvice(double temp, int humidity) {
    if (temp >= 35) {
      return 'Uống đủ nước để tránh mất nước và mệt mỏi.';
    } else if (temp >= 30) {
      return 'Thời tiết nóng, nên hạn chế ra ngoài vào giữa trưa.';
    } else if (temp >= 25) {
      if (humidity > 70) {
        return 'Thời tiết oi bức, nên mặc đồ thoáng mát.';
      }
      return 'Thời tiết dễ chịu, thích hợp cho các hoạt động ngoài trời.';
    } else if (temp >= 20) {
      return 'Thời tiết mát mẻ, phù hợp cho các hoạt động thể thao.';
    } else if (temp >= 15) {
      return 'Thời tiết se lạnh, nên mang theo áo khoác nhẹ.';
    } else {
      return 'Thời tiết lạnh, hãy giữ ấm cơ thể.';
    }
  }

  String _getUvAdvice(int uvIndex) {
    if (uvIndex >= 11) {
      return 'Cực kỳ cao! Tránh ra ngoài nếu không cần thiết.';
    } else if (uvIndex >= 8) {
      return 'Rất cao! Hạn chế ra ngoài từ 10h-16h.';
    } else if (uvIndex >= 6) {
      return 'Cao! Nên đội mũ và bôi kem chống nắng.';
    } else if (uvIndex >= 3) {
      return 'Hạn chế ra nắng lâu, nếu ra ngoài hãy\nmang mũ, kính râm và bôi kem chống nắng.';
    } else {
      return 'Mức độ an toàn, có thể hoạt động ngoài trời.';
    }
  }

  String _getGeneralAdvice(double temp) {
    if (temp >= 30) {
      return 'Không hoạt động mạnh ngoài trời lâu,\nhãy nghỉ ngơi ở nơi râm mát để bảo vệ sức khỏe.';
    } else if (temp >= 20) {
      return 'Duy trì lối sống lành mạnh,\nuống đủ nước và ăn uống điều độ.';
    } else {
      return 'Giữ ấm cơ thể,\ntăng cường vitamin C để phòng cảm cúm.';
    }
  }
}
