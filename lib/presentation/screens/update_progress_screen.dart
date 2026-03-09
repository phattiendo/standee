import 'package:flutter/material.dart';

import '../widgets/waiting_video_widget.dart';

/// Màn hình đang cập nhật tài nguyên (download, replace)
class UpdateProgressScreen extends StatelessWidget {
  const UpdateProgressScreen({
    super.key,
    this.progress = 0.0,
    this.message,
  });

  final double progress;
  final String? message;

  /// Cài đặt lần đầu: luôn hiện video Cat trong suốt lúc copy/tải vào ROM (mọi message từ runFirstTimeSetup)
  bool get _isSetup {
    final m = message ?? '';
    return m.contains('cài đặt') ||
        m.contains('tải tài nguyên') ||
        m.contains('ROM') ||
        m.contains('Copy') ||
        m.contains('Tải ảnh') ||
        m.contains('Đã lưu');
  }

  @override
  Widget build(BuildContext context) {
    final content = Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 56,
              height: 56,
              child: CircularProgressIndicator(
                value: progress > 0 && progress < 1 ? progress : null,
                color: Colors.orange,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isSetup ? 'Đang tải tài nguyên...' : 'Đang cập nhật...',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (message != null && message!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
            if (progress > 0 && progress < 1) ...[
              const SizedBox(height: 16),
              Text(
                '${(progress * 100).round()}%',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (_isSetup) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const WaitingVideoWidget(),
            // Overlay nhẹ để chữ đọc được, vẫn thấy rõ video Cat
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black26,
                    Colors.black54,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
              child: content,
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black87,
      body: content,
    );
  }
}
