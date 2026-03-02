import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Hiển thị ảnh từ URL (network) hoặc asset local
class MediaImageWidget extends StatelessWidget {
  const MediaImageWidget({
    super.key,
    required this.url,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    // Nếu là asset local (bắt đầu bằng "asset:")
    if (url.startsWith('asset:')) {
      final assetPath = url.substring(6); // Bỏ prefix "asset:"
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
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
      fit: BoxFit.cover,
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
  }
}
