import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '../storage/rom_media_storage.dart';

/// Ngưỡng seek trước khi hết (200ms) — loop mượt, decoder không reset.
const Duration _loopSeekBeforeEnd = Duration(milliseconds: 200);

/// Một Player duy nhất cho toàn app. Không tạo/dispose player mỗi video.
/// Loop: position >= duration - 200ms → seek(0), không đợi video end (tránh màn đen).
/// Chỉ phát từ file:// (ROM). Buffer 20MB cho Standee 1–2GB RAM.
class VideoService {
  VideoService._();
  static final VideoService I = VideoService._();

  static const int _bufferSizeBytes = 20 * 1024 * 1024; // 20MB

  Player? _player;
  VideoController? _videoController;
  String? _currentMediaUrl;
  bool _initialized = false;

  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration>? _durationSub;
  Duration? _durationForLoop;
  bool _seekedThisCycle = false;

  Player? get player => _player;
  VideoController? get videoController => _videoController;

  /// Đảm bảo Player + VideoController đã tạo (lazy, 1 lần).
  void ensureInitialized() {
    if (_initialized) return;
    _initialized = true;
    _player = Player(
      configuration: PlayerConfiguration(
        bufferSize: _bufferSizeBytes,
      ),
    );
    _videoController = VideoController(_player!);
    debugPrint('VideoService: single Player created (buffer ${_bufferSizeBytes ~/ (1024 * 1024)}MB)');
  }

  /// Chuyển URL hiển thị (asset:, relative path, absolute) → file:// để mở trong Player.
  /// Chỉ trả về file:// ROM. Asset phải đã copy ROM (localVideoRomPath). HTTP không dùng.
  String? resolveToFileUrl(String displayUrl) {
    if (displayUrl.isEmpty) return null;
    // Asset: chỉ phát từ ROM (copy 1 lần ở SlideshowController). Không phát asset:// hay temp.
    if (displayUrl.startsWith('asset:')) {
      final rom = RomMediaStorage.I.localVideoRomPath;
      if (rom != null && File(rom).existsSync()) return 'file://$rom';
      return null;
    }
    // Đường dẫn file: relative → full từ ROM; absolute giữ nguyên
    String pathToCheck = displayUrl.startsWith('file:') ? displayUrl.substring(5) : displayUrl;
    if (!pathToCheck.startsWith('/') && !pathToCheck.startsWith('http')) {
      final full = RomMediaStorage.I.fullPath(pathToCheck);
      if (full == null) return null;
      pathToCheck = full;
    }
    if (pathToCheck.startsWith('http')) return null; // Chỉ phát từ ROM
    if (pathToCheck.startsWith('/') && pathToCheck.length > 1) {
      if (File(pathToCheck).existsSync()) return 'file://$pathToCheck';
      return null;
    }
    return null;
  }

  /// Mở nguồn (file://). [loop]: true = seek trước khi kết thúc (không màn đen).
  /// Luôn gọi open(Media, play) khi cần phát (kể cả cùng URL) để lần đầu chắc chắn phát, không chỉ play().
  Future<void> open(String fileUrl, {bool play = true, bool loop = true}) async {
    if (fileUrl.isEmpty || !fileUrl.startsWith('file://')) {
      debugPrint('VideoService: open() chỉ chấp nhận file://, nhận: $fileUrl');
      return;
    }
    ensureInitialized();
    _stopLoop();
    final p = _player!;
    final sameUrl = _currentMediaUrl == fileUrl;
    if (sameUrl && !play) {
      if (loop) _startLoopListen();
      return;
    }
    try {
      await p.open(Media(fileUrl), play: play);
      _currentMediaUrl = fileUrl;
      if (play) await p.setVolume(100);
      if (loop) _startLoopListen();
      debugPrint('VideoService: opened $fileUrl play=$play loop=$loop');
    } catch (e) {
      debugPrint('VideoService: open failed $e');
      rethrow;
    }
  }

  /// Loop bằng seek trước khi kết thúc: position >= duration - 200ms → seek(0). Decoder không reset.
  void _startLoopListen() {
    _stopLoop();
    final p = _player;
    if (p == null) return;
    _durationForLoop = null;
    _seekedThisCycle = false;
    _positionSub = p.stream.position.listen((position) {
      final d = _durationForLoop;
      if (d == null || d.inMilliseconds < 1000) return; // Chờ duration hợp lệ, tránh seek ngay lúc đầu
      final threshold = Duration(milliseconds: d.inMilliseconds - _loopSeekBeforeEnd.inMilliseconds);
      if (position >= threshold) {
        if (!_seekedThisCycle) {
          _seekedThisCycle = true;
          // Seek xong phải play() lại, không thì vòng 2 không phát (Android có thể pause sau seek).
          p.seek(Duration.zero).then((_) => p.play()).catchError((e) {
            debugPrint('VideoService loop seek/play: $e');
            _seekedThisCycle = false;
          });
        }
      } else if (position.inMilliseconds < 2000) {
        _seekedThisCycle = false;
      }
    });
    _durationSub = p.stream.duration.listen((d) {
      if (d.inMilliseconds > 0) _durationForLoop = d;
    });
  }

  void _stopLoop() {
    _positionSub?.cancel();
    _positionSub = null;
    _durationSub?.cancel();
    _durationSub = null;
    _durationForLoop = null;
    _seekedThisCycle = false;
  }

  /// Preload = chỉ kiểm tra file sẵn sàng (file exists). Player chỉ open khi play, tránh RAM spike.
  bool isFileReady(String displayUrl) {
    final fileUrl = resolveToFileUrl(displayUrl);
    if (fileUrl == null || fileUrl.isEmpty) return false;
    if (!fileUrl.startsWith('file://')) return false;
    final path = fileUrl.substring(7);
    return File(path).existsSync();
  }

  Future<void> play() async {
    if (_player == null) return;
    await _player!.setVolume(100);
    await _player!.play();
  }

  Stream<bool> get completed => _player?.stream.completed ?? const Stream.empty();
  Stream<String> get error => _player?.stream.error ?? const Stream.empty();

  /// Chỉ gọi khi thoát app (optional). Runtime không dispose.
  Future<void> dispose() async {
    _stopLoop();
    if (_player == null) return;
    try {
      await _player!.stop();
    } catch (_) {}
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      await _player!.dispose();
    } catch (_) {}
    _player = null;
    _videoController = null;
    _currentMediaUrl = null;
    _initialized = false;
  }
}
