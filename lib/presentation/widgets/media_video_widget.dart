import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/audio/background_audio_service.dart';


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
  Player? _player;
  VideoController? _videoController;
  
  bool _initialized = false;
  bool _hasError = false;
  bool _disposed = false;
  String? _errorMessage;
  bool _endedNotified = false;

  StreamSubscription? _completedSub;
  StreamSubscription? _errorSub;

  // Cache cho asset video
  static final Map<String, String> _assetCache = {};

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  Future<void> _initializeVideo() async {
    if (_disposed) return;

    try {
      // 1. Tắt background audio TRƯỚC
      await BackgroundAudioService.I.fadeOutAndPause();
      await Future.delayed(const Duration(milliseconds: 150));

      if (_disposed) return;

      // 2. Tạo player
      _player = Player();
      _videoController = VideoController(_player!);

      // 3. Listen events
      _completedSub = _player!.stream.completed.listen((completed) {
        if (completed && !_endedNotified) {
          debugPrint('Video completed');
          _notifyEnded();
        }
      });

      _errorSub = _player!.stream.error.listen((error) {
        if (error.isNotEmpty && !_hasError) {
          debugPrint('Video error: $error');
          _handleError(error);
        }
      });

      // 4. Chuẩn bị media URL
      String mediaUrl;
      if (widget.url.startsWith('asset:')) {
        // Copy asset ra temp file (media_kit cần file path thật)
        mediaUrl = await _getAssetFilePath(widget.url.substring(6));
      } else {
        mediaUrl = widget.url;
      }

      if (_disposed || !mounted) {
        await _safeDispose();
        return;
      }

      debugPrint('Opening video: $mediaUrl');

      // 5. Mở video
      await _player!.open(Media(mediaUrl), play: false);

      if (_disposed || !mounted) {
        await _safeDispose();
        return;
      }

      // 6. Set volume
      await _player!.setVolume(100);

      setState(() => _initialized = true);

      // 7. Play
      await _player!.play();
      widget.onVideoStarted?.call();

      debugPrint('Video playing: ${widget.url}');
    } catch (e) {
      debugPrint('Video init error: $e');
      _handleError(e.toString());
    }
  }


  Future<String> _getAssetFilePath(String assetPath) async {
    // Check cache
    if (_assetCache.containsKey(assetPath)) {
      final cachedPath = _assetCache[assetPath]!;
      if (await File(cachedPath).exists()) {
        return cachedPath;
      }
    }

    // Copy asset to temp
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final tempFile = File('${tempDir.path}/$fileName');

    if (!await tempFile.exists()) {
      final data = await rootBundle.load(assetPath);
      await tempFile.writeAsBytes(data.buffer.asUint8List());
      debugPrint('Copied asset to: ${tempFile.path}');
    }

    _assetCache[assetPath] = tempFile.path;
    return tempFile.path;
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

  Future<void> _safeDispose() async {
    _completedSub?.cancel();
    _errorSub?.cancel();
    
    final player = _player;
    _player = null;
    _videoController = null;
    
    if (player != null) {
      try {
        await player.stop();
      } catch (_) {}
      
      await Future.delayed(const Duration(milliseconds: 300));
      
      try {
        await player.dispose();
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _disposed = true;
    
    _safeDispose().then((_) {
      BackgroundAudioService.I.resumeAndFadeIn();
    });

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
              const Text(
                'Video unavailable',
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _errorMessage!.length > 50
                        ? '${_errorMessage!.substring(0, 50)}...'
                        : _errorMessage!,
                    style: const TextStyle(color: Colors.white24, fontSize: 10),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              const Text(
                'Skipping...',
                style: TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],
          ),
        ),
      );
    }

    if (!_initialized || _videoController == null) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
              SizedBox(height: 12),
              Text(
                'Loading video...',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Video(
        controller: _videoController!,
        fill: Colors.black,
      ),
    );
  }
}
