import 'dart:ui';

import 'package:flutter/material.dart';

/// Widget tạo hiệu ứng glass bằng BackdropFilter (custom, không dùng package).
/// Blur 18, gradient 25%→10%, border 1.2px 30%.
class LiquidGlassContainer extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final double blurSigma;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.blurSigma = 18,
    this.padding,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: padding ?? const EdgeInsets.all(16),
      child: child,
    );

    final glass = ClipRRect(
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
              content,
            ],
          ),
        ),
      ),
    );

    return margin != null ? Padding(padding: margin!, child: glass) : glass;
  }
}
