import 'package:flutter/material.dart';

import '../../../data/models/speed_test_model.dart';
import 'speed_gauge_painter.dart';

/// Section hiển thị Internet Speed trong SDP với scale support
class SpeedSection extends StatelessWidget {
  final SpeedTestData speedTest;
  final double scale;

  const SpeedSection({
    super.key,
    required this.speedTest,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.wifi,
                  color: Colors.white.withValues(alpha: 0.8),
                  size: 24 * scale,
                ),
                SizedBox(width: 8 * scale),
                Text(
                  'Internet\nSpeed',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14 * scale,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Updated',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12 * scale,
                  ),
                ),
                Text(
                  speedTest.formattedUpdateTime,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13 * scale,
                  ),
                ),
              ],
            ),
          ],
        ),

        const Spacer(),

        // Speed Gauge
        Center(
          child: SpeedGaugeWidget(
            value: speedTest.downloadSpeed,
            maxValue: 200,
            scale: scale,
          ),
        ),

        const Spacer(),

        // Details: Ping, Download, Upload
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSpeedItem('Ping', '${speedTest.ping}', 'ms'),
            _buildSpeedItem(
              'Download',
              speedTest.downloadSpeed.toStringAsFixed(0),
              'Mbps',
            ),
            _buildSpeedItem(
              'Upload',
              speedTest.uploadSpeed.toStringAsFixed(0),
              'Mbps',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpeedItem(String label, String value, String unit) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13 * scale,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 22 * scale,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12 * scale,
          ),
        ),
      ],
    );
  }
}
