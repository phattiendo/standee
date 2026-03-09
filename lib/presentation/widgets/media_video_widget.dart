import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../../core/audio/background_audio_service.dart';
import '../../core/video/video_service.dart';

/// Phát video qua [VideoService] (1 Player duy nhất). Chỉ phát từ file:// ROM.
/// [url]: asset:, relative path, hoặc absolute → resolve thành file:// trong service.
/// Không tạo/dispose player → tránh lag, màn đen, fragment RAM.
class MediaVideoWidget extends StatefulWidget {
  const MediaVideoWidget({
    super.key,
    required this.url,
    this.onVideoStarted,
    this.onVideoEnded,
  });

  final String url;
  final VoidCallback? onVideoStarted;
  final VoidCallback? onVideoEnded;

  @override
  State<MediaVideoWidget> createState() => _MediaVideoWidgetState();
}

class _MediaVideoWidgetState extends State<MediaVideoWidget> {
  bool _initialized = false;
  bool _hasError = false;
  bool _disposed = false;
  String? _errorMessage;
  bool _endedNotified = false;

  StreamSubscription<bool>? _completedSub;
  StreamSubscription<String>? _errorSub;

  @override
  void initState() {
    super.initState();
    _attachAndPlay();
  }

  Future<void> _attachAndPlay() async {
    if (_disposed) return;
    VideoService.I.ensureInitialized();
    if (mounted) setState(() => _initialized = true);

    await BackgroundAudioService.I.fadeOutAndPause();
    await Future.delayed(const Duration(milliseconds: 80));
    if (_disposed || !mounted) return;

    final fileUrl = VideoService.I.resolveToFileUrl(widget.url);
    if (fileUrl == null || fileUrl.isEmpty) {
      _handleError('Video chưa sẵn sàng (ROM)');
      return;
    }

    _completedSub = VideoService.I.completed.listen((completed) {
      if (completed && !_endedNotified) _notifyEnded();
    });
    _errorSub = VideoService.I.error.listen((error) {
      if (error.isNotEmpty && !_hasError) _handleError(error);
    });

    await Future.delayed(const Duration(milliseconds: 50));
    if (_disposed || !mounted) return;

    try {
      await VideoService.I.open(fileUrl, play: true);
      if (_disposed || !mounted) return;
      widget.onVideoStarted?.call();
      debugPrint('MediaVideoWidget: playing $fileUrl');
    } catch (e) {
      debugPrint('MediaVideoWidget: open error $e');
      _handleError(e.toString());
    }
  }

  void _handleError(String message) {
    if (_disposed || _endedNotified) return;
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = message;
      });
    }
    Future.delayed(const Duration(milliseconds: 1200), () {
      _notifyEnded();
    });
  }

  void _notifyEnded() {
    if (_endedNotified || _disposed) return;
    _endedNotified = true;
    widget.onVideoEnded?.call();
  }

  @override
  void dispose() {
    _disposed = true;
    _completedSub?.cancel();
    _errorSub?.cancel();
    _completedSub = null;
    _errorSub = null;
    // Nhạc nền do SlideshowController._handleAudioTransition xử lý khi chuyển slide
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.videocam_off, color: Colors.white38, size: 48),
              const SizedBox(height: 8),
              const Text('Video unavailable', style: TextStyle(color: Colors.white54, fontSize: 14)),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage!.length > 50 ? '${_errorMessage!.substring(0, 50)}...' : _errorMessage!,
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              const SizedBox(height: 8),
              const Text('Skipping...', style: TextStyle(color: Colors.white38, fontSize: 11)),
            ],
          ),
        ),
      );
    }

    if (!_initialized || VideoService.I.videoController == null) {
      return const ColoredBox(color: Colors.black);
    }

    return ColoredBox(
      color: Colors.black,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth > 0 ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
          final h = constraints.maxHeight > 0 ? constraints.maxHeight : MediaQuery.sizeOf(context).height;
          return SizedBox(
            width: w,
            height: h,
            child: Video(
              controller: VideoService.I.videoController!,
              fit: BoxFit.contain,
              fill: Colors.black,
            ),
          );
        },
      ),
    );
  }
}
