import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:liquid_glass_renderer/liquid_glass_renderer.dart';

/// Kiểu glass effect
enum GlassType {
  /// Dùng liquid_glass_renderer package (cần Impeller)
  liquidGlass,
  /// Dùng FakeGlass từ package (nhẹ hơn)
  fakeGlass,
  /// Dùng BackdropFilter (tương thích mọi renderer)
  backdrop,
}

/// Widget tạo hiệu ứng Liquid Glass
/// 
/// Công thức chuẩn (Blur 18, Gradient 25%→10%, Border 1.2px 30%):
/// - [GlassType.backdrop]: Tương thích nhất, khuyên dùng cho thiết bị yếu
/// - [GlassType.fakeGlass]: Dùng package, nhẹ
/// - [GlassType.liquidGlass]: Đẹp nhất nhưng cần Impeller
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final GlassType glassType;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blurSigma = 18,
    this.glassType = GlassType.backdrop,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    Widget glass;
    switch (glassType) {
      case GlassType.liquidGlass:
        glass = _buildLiquidGlass(content);
      case GlassType.fakeGlass:
        glass = _buildFakeGlass(content);
      case GlassType.backdrop:
        glass = _buildBackdropGlass(content);
    }

    return margin != null ? Padding(padding: margin!, child: glass) : glass;
  }

  Widget _buildLiquidGlass(Widget child) {
    return LiquidGlass.withOwnLayer(
      shape: LiquidRoundedRectangle(borderRadius: borderRadius),
      settings: LiquidGlassSettings(
        thickness: blurSigma,
        lightAngle: 0.5 * math.pi,
        chromaticAberration: 1,
      ),
      child: child,
    );
  }

  Widget _buildFakeGlass(Widget child) {
    return FakeGlass(
      shape: LiquidRoundedRectangle(borderRadius: borderRadius),
      settings: LiquidGlassSettings(
        thickness: blurSigma,
        lightAngle: 0.5 * math.pi,
        chromaticAberration: 1,
      ),
      child: child,
    );
  }

  Widget _buildBackdropGlass(Widget child) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(255, 255, 255, 0.25),
                Color.fromRGBO(255, 255, 255, 0.10),
              ],
            ),
            border: Border.all(
              color: const Color.fromRGBO(255, 255, 255, 0.30),
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(borderRadius),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.center,
                      colors: [
                        Color.fromRGBO(255, 255, 255, 0.40),
                        Color.fromRGBO(255, 255, 255, 0.0),
                      ],
                      stops: [0.0, 0.5],
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}
