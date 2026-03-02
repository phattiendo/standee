import 'dart:math' as math;

import 'package:flutter/material.dart';

/// CustomPainter vẽ Speed Gauge nhẹ, tối ưu cho thiết bị RAM thấp
class SpeedGaugePainter extends CustomPainter {
  final double value; // Giá trị hiện tại (Mbps)
  final double maxValue; // Giá trị max của gauge
  final Color startColor;
  final Color endColor;
  final Color backgroundColor;
  final double strokeWidth;

  SpeedGaugePainter({
    required this.value,
    this.maxValue = 200,
    this.startColor = const Color(0xFF00C853),
    this.endColor = const Color(0xFFFF5252),
    this.backgroundColor = const Color(0x33FFFFFF),
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.85);
    final radius = math.min(size.width, size.height) * 0.7;

    // Góc bắt đầu và kết thúc (arc 180 độ)
    const startAngle = math.pi; // 180 độ
    const sweepAngle = math.pi; // 180 độ

    // Vẽ background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      bgPaint,
    );

    // Vẽ value arc với gradient
    final valueRatio = (value / maxValue).clamp(0.0, 1.0);
    final valueSweep = sweepAngle * valueRatio;

    if (valueSweep > 0) {
      final gradient = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
        colors: [startColor, endColor],
        stops: const [0.0, 1.0],
      );

      final valuePaint = Paint()
        ..shader = gradient.createShader(
          Rect.fromCircle(center: center, radius: radius),
        )
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        valueSweep,
        false,
        valuePaint,
      );
    }

    // Vẽ kim chỉ
    final needleAngle = startAngle + (valueSweep);
    final needleLength = radius - strokeWidth;
    final needleEnd = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleEnd, needlePaint);

    // Vẽ circle center
    final centerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, 8, centerPaint);
  }

  @override
  bool shouldRepaint(SpeedGaugePainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

/// Widget wrapper cho SpeedGaugePainter với RepaintBoundary và scale support
class SpeedGaugeWidget extends StatelessWidget {
  final double value;
  final double maxValue;
  final double scale;

  const SpeedGaugeWidget({
    super.key,
    required this.value,
    this.maxValue = 200,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 140 * scale,
            height: 90 * scale,
            child: CustomPaint(
              painter: SpeedGaugePainter(
                value: value,
                maxValue: maxValue,
                strokeWidth: 14 * scale,
              ),
            ),
          ),
          SizedBox(height: 4 * scale),
          Text(
            value.toStringAsFixed(1),
            style: TextStyle(
              color: const Color(0xFFFF5722),
              fontSize: 24 * scale,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'Mbps',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12 * scale,
            ),
          ),
        ],
      ),
    );
  }
}
