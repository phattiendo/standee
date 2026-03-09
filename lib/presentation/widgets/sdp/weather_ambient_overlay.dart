import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../data/models/weather_model.dart';

/// Cập nhật ~30 lần/giây thay vì 60 để animation mượt hơn trên máy yếu.
const int _ambientFps = 30;
const Duration _ambientTickPeriod = Duration(milliseconds: 33);

/// Asset ảnh mây cho hiệu ứng mây mù (cloudy/foggy).
const String _cloudAsset1 = 'assets/may1.png';
const String _cloudAsset2 = 'assets/may2.png';

/// Hiệu ứng ambient theo thời tiết: nắng = lá/hoa rơi, mưa = mưa rơi, nhiều mây = mây bay (dùng ảnh may1/may2).
class WeatherAmbientOverlay extends StatefulWidget {
  final WeatherData weather;
  final bool enabled;

  const WeatherAmbientOverlay({
    super.key,
    required this.weather,
    this.enabled = true,
  });

  @override
  State<WeatherAmbientOverlay> createState() => _WeatherAmbientOverlayState();
}

class _WeatherAmbientOverlayState extends State<WeatherAmbientOverlay> {
  final ValueNotifier<double> _value = ValueNotifier(0.0);
  Timer? _timer;
  ui.Image? _cloudImage1;
  ui.Image? _cloudImage2;

  /// Một vòng 22 giây ở 30fps → mây bay nhanh hơn, mượt hơn (trước 36s).
  static const double _stepPerTick = 1.0 / (22 * _ambientFps);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(_ambientTickPeriod, _onTick);
    _loadCloudImages();
  }

  void _onTick(Timer t) {
    if (!mounted) {
      t.cancel();
      return;
    }
    _value.value = (_value.value + _stepPerTick) % 1.0;
  }

  Future<void> _loadCloudImages() async {
    try {
      final data1 = await rootBundle.load(_cloudAsset1);
      final data2 = await rootBundle.load(_cloudAsset2);
      ui.decodeImageFromList(data1.buffer.asUint8List(), (ui.Image img) {
        if (mounted) setState(() => _cloudImage1 = img);
      });
      ui.decodeImageFromList(data2.buffer.asUint8List(), (ui.Image img) {
        if (mounted) setState(() => _cloudImage2 = img);
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _timer?.cancel();
    _value.dispose();
    _cloudImage1?.dispose();
    _cloudImage2?.dispose();
    _cloudImage1 = null;
    _cloudImage2 = null;
    super.dispose();
  }

  static _AmbientType _typeFromCondition(String condition, int weatherCode) {
    final c = condition.toLowerCase().trim();
    // Ưu tiên mã WMO: 51-57 drizzle, 61-67 80-82 rain, 95-99 thunderstorm → mưa
    if (weatherCode >= 51 && weatherCode <= 57) return _AmbientType.rain;
    if (weatherCode >= 61 && weatherCode <= 67) return _AmbientType.rain;
    if (weatherCode >= 80 && weatherCode <= 82) return _AmbientType.rain;
    if (weatherCode >= 95 && weatherCode <= 99) return _AmbientType.rain;
    if (c == 'sunny') return _AmbientType.leaves;
    // Mưa theo condition string
    if (c == 'rainy' || c == 'drizzle' || c == 'rain' ||
        c.contains('rain') || c.contains('drizzle') ||
        c == 'freezing_rain' || c == 'thunderstorm' || c == 'thunderstorm_hail') {
      return _AmbientType.rain;
    }
    if (c == 'cloudy' || c == 'foggy' || c == 'unknown') return _AmbientType.clouds;
    return _AmbientType.clouds;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return const SizedBox.shrink();

    final type = _typeFromCondition(
      widget.weather.condition,
      widget.weather.weatherCode,
    );

    return IgnorePointer(
      child: RepaintBoundary(
        child: SizedBox.expand(
          child: AnimatedBuilder(
            animation: _value,
            builder: (context, child) {
              return CustomPaint(
                painter: _AmbientPainter(
                  type: type,
                  value: _value.value,
                  cloudImage1: _cloudImage1,
                  cloudImage2: _cloudImage2,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

enum _AmbientType { leaves, rain, clouds }

class _AmbientPainter extends CustomPainter {
  final _AmbientType type;
  final double value;
  final ui.Image? cloudImage1;
  final ui.Image? cloudImage2;

  _AmbientPainter({
    required this.type,
    required this.value,
    this.cloudImage1,
    this.cloudImage2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case _AmbientType.leaves:
        _paintLeaves(canvas, size);
        break;
      case _AmbientType.rain:
        _paintRain(canvas, size);
        break;
      case _AmbientType.clouds:
        _paintClouds(canvas, size);
        break;
    }
  }

  /// Lá/hoa rơi nhẹ (nắng) — giảm count để mượt trên máy yếu
  void _paintLeaves(Canvas canvas, Size size) {
    const count = 18;
    final rnd = math.Random(42);

    for (var i = 0; i < count; i++) {
      final seed = i / count + value;
      final x = (rnd.nextDouble() * 1.2 - 0.1) * size.width;
      final y = (seed % 1.0) * (size.height + 80) - 40;
      final sway = math.sin(seed * math.pi * 4) * 12;
      final radius = 4.0 + rnd.nextDouble() * 6;
      // Màu lá/hoa: xanh lá, vàng nhạt, cam nhạt
      final hueChoice = rnd.nextInt(3);
      final leafColor = [
        const Color(0xFF6B8E23).withOpacity(0.4),
        const Color(0xFFDAA520).withOpacity(0.35),
        const Color(0xFFCD853F).withOpacity(0.35),
      ][hueChoice];

      final cx = x + sway;
      final rect = Rect.fromCenter(
        center: Offset(cx, y),
        width: radius * 2,
        height: radius * 2.4,
      );

      final paint = Paint()
        ..color = leafColor
        ..style = PaintingStyle.fill;
      canvas.save();
      canvas.translate(cx, y);
      canvas.rotate(seed * 2);
      canvas.translate(-cx, -y);
      canvas.drawOval(rect, paint);
      canvas.restore();
    }
  }

  /// Mưa rơi — giảm tia để mượt (55 thay 120)
  void _paintRain(Canvas canvas, Size size) {
    const count = 55;
    final rnd = math.Random(123);

    for (var i = 0; i < count; i++) {
      final seed = i / count + value;
      final x = (rnd.nextDouble() * 1.1) * size.width;
      final y = (seed % 1.0) * (size.height + 80) - 20;
      final len = 12.0 + rnd.nextDouble() * 18;
      final thickness = 1.2 + rnd.nextDouble() * 0.8;
      final slant = 3.0 + rnd.nextDouble() * 2;

      final paint = Paint()
        ..color = Colors.white.withOpacity(0.45)
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + slant, y + len),
        paint,
      );
    }
  }

  /// Mây bay ngang — ít mây + vẽ nhỏ hơn để mượt; FilterQuality.low giảm tốn GPU.
  void _paintClouds(Canvas canvas, Size size) {
    const count = 5;
    final rnd = math.Random(7);
    final useImages = cloudImage1 != null || cloudImage2 != null;
    final images = [cloudImage1, cloudImage2].whereType<ui.Image>().toList();

    for (var i = 0; i < count; i++) {
      final seed = i / count + value;
      final baseX = (seed % 1.2) * size.width - size.width * 0.1;
      final baseY = size.height * (0.15 + rnd.nextDouble() * 0.4);
      final w = 60.0 + rnd.nextDouble() * 80;
      final h = 22.0 + rnd.nextDouble() * 28;

      if (useImages && images.isNotEmpty) {
        final img = images[i % images.length];
        final src = Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble());
        final dst = Rect.fromCenter(center: Offset(baseX, baseY), width: w, height: h);
        final paint = Paint()..filterQuality = FilterQuality.low;
        canvas.drawImageRect(img, src, dst, paint);
      } else {
        final rect = Rect.fromCenter(
          center: Offset(baseX, baseY),
          width: w,
          height: h,
        );
        final paint = Paint()
          ..color = Colors.white.withOpacity(0.12)
          ..style = PaintingStyle.fill;
        canvas.drawOval(rect, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.value != value ||
        oldDelegate.cloudImage1 != cloudImage1 ||
        oldDelegate.cloudImage2 != cloudImage2;
  }
}
