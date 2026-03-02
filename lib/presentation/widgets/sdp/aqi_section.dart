import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/air_quality_model.dart';
import 'aqi_bar_painter.dart';

/// Section hiển thị Air Quality Index trong SDP với scale support
class AqiSection extends StatelessWidget {
  final AirQualityData airQuality;
  final double scale;

  const AqiSection({
    super.key,
    required this.airQuality,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 8 * scale,
                vertical: 4 * scale,
              ),
              decoration: BoxDecoration(
                color: _getAqiColor(airQuality.usAqi),
                borderRadius: BorderRadius.circular(6 * scale),
              ),
              child: Text(
                'Great air\nhere today',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
            ),
            SizedBox(width: 12 * scale),
            Text(
              '${airQuality.usAqi}',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 12 * scale),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CAQI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Updated',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12 * scale,
                  ),
                ),
                Text(
                  _getTimeString(),
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12 * scale,
                  ),
                ),
              ],
            ),
          ],
        ),

        const Spacer(),

        // AQI Bar
        AqiBarWidget(
          o2Value: airQuality.estimatedO2,
          co2Value: airQuality.estimatedCo2,
          dustValue: airQuality.dust,
          scale: scale,
        ),
      ],
    );
  }

  Color _getAqiColor(int aqi) {
    if (aqi <= 50) return const Color(0xFF00E400);
    if (aqi <= 100) return const Color(0xFFFFFF00);
    if (aqi <= 150) return const Color(0xFFFF7E00);
    if (aqi <= 200) return const Color(0xFFFF0000);
    if (aqi <= 300) return const Color(0xFF8F3F97);
    return const Color(0xFF7E0023);
  }

  String _getTimeString() {
    final time = airQuality.time ?? DateTime.now();
    return DateFormat('h:mm a').format(time);
  }
}
