import 'package:flutter/material.dart';

/// CustomPainter vẽ thanh AQI gradient (O2 - CO2 - Dust)
class AqiBarPainter extends CustomPainter {
  final double value; // 0.0 - 1.0 (vị trí trên thanh)
  final double barHeight;

  AqiBarPainter({
    required this.value,
    this.barHeight = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final barRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, (size.height - barHeight) / 2, size.width, barHeight),
      Radius.circular(barHeight / 2),
    );

    // Gradient từ xanh -> vàng -> cam -> đỏ
    final gradient = const LinearGradient(
      colors: [
        Color(0xFF00E400), // Good - Green
        Color(0xFFFFFF00), // Moderate - Yellow
        Color(0xFFFF7E00), // Unhealthy for Sensitive - Orange
        Color(0xFFFF0000), // Unhealthy - Red
      ],
      stops: [0.0, 0.33, 0.66, 1.0],
    );

    final barPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromLTWH(0, 0, size.width, barHeight),
      );

    canvas.drawRRect(barRect, barPaint);

    // Vẽ indicator (tam giác nhỏ phía trên)
    final indicatorX = size.width * value.clamp(0.0, 1.0);
    final indicatorY = (size.height - barHeight) / 2 - 4;

    final indicatorPath = Path()
      ..moveTo(indicatorX - 6, indicatorY - 8)
      ..lineTo(indicatorX + 6, indicatorY - 8)
      ..lineTo(indicatorX, indicatorY)
      ..close();

    final indicatorPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawPath(indicatorPath, indicatorPaint);
  }

  @override
  bool shouldRepaint(AqiBarPainter oldDelegate) {
    return oldDelegate.value != value;
  }
}

/// Widget hiển thị thanh AQI với labels và scale support
class AqiBarWidget extends StatelessWidget {
  final double o2Value;
  final double co2Value;
  final double dustValue;
  final double scale;

  const AqiBarWidget({
    super.key,
    required this.o2Value,
    required this.co2Value,
    required this.dustValue,
    this.scale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    // Tính vị trí indicator dựa trên CO2 (giá trị chính)
    final indicatorPosition = (co2Value / 500).clamp(0.0, 1.0);

    return RepaintBoundary(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 35 * scale,
            child: CustomPaint(
              size: Size(double.infinity, 35 * scale),
              painter: AqiBarPainter(
                value: indicatorPosition,
                barHeight: 10 * scale,
              ),
            ),
          ),
          SizedBox(height: 12 * scale),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLabel('O2', '${o2Value.toStringAsFixed(0)} ppm'),
              _buildLabel('Co2', '${co2Value.toStringAsFixed(0)} ppm'),
              _buildLabel('Dust', '${dustValue.toStringAsFixed(0)} ppm'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12 * scale,
          ),
        ),
        SizedBox(height: 2 * scale),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
