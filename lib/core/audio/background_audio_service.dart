import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

/// Service quản lý nhạc nền cho slideshow
class BackgroundAudioService {
  BackgroundAudioService._();
  static final BackgroundAudioService I = BackgroundAudioService._();

  AudioPlayer? _player;
  bool _initialized = false;
  bool _enabled = true;
  bool _initializing = false;

  bool get isInitialized => _initialized;
  bool get enabled => _enabled;
  
  set enabled(bool value) {
    _enabled = value;
    if (!value) {
      _player?.pause();
    } else if (_initialized) {
      _player?.play();
    }
  }

  bool get isPlaying => _player?.playing ?? false;
  double get volume => _player?.volume ?? 1.0;

  /// Khởi tạo audio - không block, chạy background.
  /// Nếu [filePath] có (nhạc đã copy vào ROM) thì phát từ file, không thì phát từ [assetPath].
  Future<void> init({
    String assetPath = 'assets/emlakothe.mp3',
    String? filePath,
  }) async {
    if (_initialized || _initializing) return;
    _initializing = true;

    try {
      _player = AudioPlayer();

      final useFile = filePath != null && filePath.isNotEmpty;
      if (useFile) {
        await _player!.setUrl('file://$filePath').timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Audio load timeout');
            return const Duration(seconds: 0);
          },
        );
      } else {
        await _player!.setAsset(assetPath).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Audio load timeout');
            return const Duration(seconds: 0);
          },
        );
      }

      await _player!.setLoopMode(LoopMode.one);
      await _player!.setVolume(1.0);

      _initialized = true;

      if (_enabled) {
        _player!.play();
      }

      debugPrint('Audio initialized successfully');
    } catch (e) {
      debugPrint('Audio init error: $e');
      _initialized = false;
    } finally {
      _initializing = false;
    }
  }

  /// Fade out và pause
  Future<void> fadeOutAndPause({Duration duration = const Duration(milliseconds: 300)}) async {
    if (_player == null || !_initialized) return;

    try {
      final startVolume = _player!.volume;
      const steps = 6;
      final stepDuration = duration ~/ steps;

      for (var i = 1; i <= steps; i++) {
        if (_player == null) return;
        await Future.delayed(stepDuration);
        final newVolume = (startVolume * (1 - i / steps)).clamp(0.0, 1.0);
        await _player?.setVolume(newVolume);
      }

      await _player?.pause();
    } catch (e) {
      debugPrint('Fade out error: $e');
    }
  }

  /// Resume và fade in
  Future<void> resumeAndFadeIn({Duration duration = const Duration(milliseconds: 300)}) async {
    if (_player == null || !_initialized || !_enabled) return;

    try {
      await _player!.setVolume(0.0);
      await _player!.play();

      const steps = 6;
      final stepDuration = duration ~/ steps;

      for (var i = 1; i <= steps; i++) {
        if (_player == null) return;
        await Future.delayed(stepDuration);
        final newVolume = (i / steps).clamp(0.0, 1.0);
        await _player?.setVolume(newVolume);
      }
    } catch (e) {
      debugPrint('Fade in error: $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player?.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    if (!_enabled || !_initialized) return;
    try {
      await _player?.play();
    } catch (_) {}
  }

  Future<void> setVolume(double volume) async {
    try {
      await _player?.setVolume(volume.clamp(0.0, 1.0));
    } catch (_) {}
  }

  Future<void> dispose() async {
    try {
      await _player?.dispose();
    } catch (_) {}
    _player = null;
    _initialized = false;
  }
}
