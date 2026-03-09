import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

/// Giới hạn decode tối đa (tránh tốn RAM trên màn rất lớn).
const int _decodeCap = 1920;

/// Hiển thị ảnh từ URL (network), asset local, hoặc file trên ROM.
/// [fit]: cover = phủ toàn màn (poster full màn standee), contain = xem hết ảnh trong ô (vd ô SDP).
/// Decode đúng kích thước hiển thị (từ LayoutBuilder) để load nhanh.
class MediaImageWidget extends StatelessWidget {
  const MediaImageWidget({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
  });

  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.of(context).devicePixelRatio;
        final w = constraints.maxWidth.isFinite && constraints.maxWidth > 0
            ? (constraints.maxWidth * dpr).round().clamp(1, _decodeCap)
            : _decodeCap;
        final h = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? (constraints.maxHeight * dpr).round().clamp(1, _decodeCap)
            : _decodeCap;

        // File trên ROM
        if (url.startsWith('/') || url.startsWith('file://')) {
          final path = url.startsWith('file://') ? url.substring(7) : url;
          final file = File(path);
          return Image(
            image: ResizeImage.resizeIfNeeded(w, h, FileImage(file)),
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: Colors.black,
              child: Center(
                child: Icon(Icons.broken_image, color: Colors.white38, size: 48),
              ),
            ),
          );
        }

        // Asset local
        if (url.startsWith('asset:')) {
          final assetPath = url.substring(6).trim();
          return Image(
            image: ResizeImage.resizeIfNeeded(w, h, AssetImage(assetPath)),
            fit: fit,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => const ColoredBox(
              color: Colors.black,
              child: Center(
                child: Icon(Icons.broken_image, color: Colors.white38, size: 48),
              ),
            ),
          );
        }

        // Network image
        return CachedNetworkImage(
          imageUrl: url,
          fit: fit,
          width: double.infinity,
          height: double.infinity,
          placeholder: (context, _) => const ColoredBox(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          errorWidget: (context, url, error) => const ColoredBox(
            color: Colors.black,
            child: Center(
              child: Icon(Icons.broken_image, color: Colors.white38, size: 48),
            ),
          ),
        );
      },
    );
  }
}
