import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/weather_model.dart';

/// Section hiển thị thông tin thời tiết trong SDP với Liquid Glass
class WeatherSection extends StatelessWidget {
  final WeatherData weather;
  final String location;
  final double scale;

  const WeatherSection({
    super.key,
    required this.weather,
    this.location = 'BINH DUONG - TP HO CHI MINH',
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header: Location + Date + Update time
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22 * scale,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    _getDateString(),
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14 * scale,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _getTimeString(),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14 * scale,
                  ),
                ),
                Text(
                  'Updated',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12 * scale,
                  ),
                ),
              ],
            ),
          ],
        ),

        SizedBox(height: 24 * scale),

        // Main weather info
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Humidity
              _buildWeatherItem(
                '${weather.humidity}%',
                'Humidity',
              ),

              // Temperature (main)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${weather.temperature.round()}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 80 * scale,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      Text(
                        '°',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 40 * scale,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 12 * scale),
                      _getWeatherIcon(weather.condition, size: 56 * scale),
                    ],
                  ),
                  SizedBox(height: 8 * scale),
                  Text(
                    'Feels Like ${weather.feelsLike.round()}°',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16 * scale,
                    ),
                  ),
                  SizedBox(height: 4 * scale),
                  Text(
                    'High ${weather.highTemp.round()}° · Low ${weather.lowTemp.round()}°',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14 * scale,
                    ),
                  ),
                ],
              ),

              // UV Index
              _buildWeatherItem(
                weather.uvIndex.toStringAsFixed(1),
                'UV ${weather.uvDescription}',
              ),
            ],
          ),
        ),

        SizedBox(height: 16 * scale),

        // Hourly forecast
        _buildHourlyForecast(),
      ],
    );
  }

  Widget _buildWeatherItem(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 42 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 4 * scale),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 14 * scale,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast() {
    // Tạo dummy data nếu không có forecast
    final forecasts = weather.hourlyForecast.isNotEmpty
        ? weather.hourlyForecast.take(8).toList()
        : List.generate(
            8,
            (i) => HourlyForecast(
              time: '${(DateTime.now().hour + i) % 24}:00',
              temperature: weather.temperature + (i - 4) * 0.5,
              weatherCode: weather.weatherCode,
              condition: weather.condition,
            ),
          );

    return SizedBox(
      height: 90 * scale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: forecasts.map((forecast) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${forecast.temperature.round()}°',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18 * scale,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4 * scale),
              _getWeatherIcon(forecast.condition, size: 28 * scale),
              SizedBox(height: 4 * scale),
              Text(
                forecast.time.isEmpty ? 'Now' : forecast.time,
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12 * scale,
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _getWeatherIcon(String condition, {double size = 32}) {
    IconData iconData;
    Color iconColor = Colors.orange;

    switch (condition.toLowerCase()) {
      case 'sunny':
        iconData = Icons.wb_sunny;
        iconColor = Colors.orange;
        break;
      case 'cloudy':
        iconData = Icons.cloud;
        iconColor = Colors.white70;
        break;
      case 'rainy':
      case 'drizzle':
      case 'freezing_rain':
      case 'freezing_drizzle':
        iconData = Icons.water_drop;
        iconColor = Colors.blue;
        break;
      case 'thunderstorm':
      case 'thunderstorm_hail':
        iconData = Icons.thunderstorm;
        iconColor = Colors.purple;
        break;
      case 'snowy':
      case 'snow_grains':
        iconData = Icons.ac_unit;
        iconColor = Colors.lightBlue;
        break;
      case 'foggy':
        iconData = Icons.foggy;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.wb_cloudy;
        iconColor = Colors.white70;
    }

    return Icon(iconData, color: iconColor, size: size);
  }

  String _getDateString() {
    final now = DateTime.now();
    return DateFormat('dd/MM MMMM').format(now);
  }

  String _getTimeString() {
    final now = DateTime.now();
    return DateFormat('h:mm a').format(now);
  }
}
