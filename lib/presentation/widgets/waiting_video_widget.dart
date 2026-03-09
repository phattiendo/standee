import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/storage/rom_media_storage.dart';

/// Video hiệu ứng chờ (Cat playing) — phát từ ROM nếu đã copy, không thì từ temp. Lặp, tắt tiếng.
/// Dùng cho LoadingScreen và màn cài đặt (UpdateProgressScreen).
class WaitingVideoWidget extends StatefulWidget {
  const WaitingVideoWidget({super.key});

  @override
  State<WaitingVideoWidget> createState() => _WaitingVideoWidgetState();
}

class _WaitingVideoWidgetState extends State<WaitingVideoWidget> {
  /// Dùng catoon1.mp4 (asset có sẵn). Nếu có file "Cat playing animation.mp4" thì đổi lại.
  static const String _assetPath = 'assets/catoon1.mp4';
  Player? _player;
  VideoController? _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      String mediaUrl;
      final romPath = RomMediaStorage.I.setupWaitingVideoRomPath;
      if (romPath != null && File(romPath).existsSync()) {
        mediaUrl = 'file://$romPath';
      } else {
        final bytes = await rootBundle.load(_assetPath);
        final tempDir = await getTemporaryDirectory();
        final name = _assetPath.replaceAll('/', '_');
        final file = File('${tempDir.path}/$name');
        await file.writeAsBytes(
          bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
        );
        mediaUrl = 'file://${file.path}';
      }

      _player = Player();
      _controller = VideoController(_player!);
      await _player!.open(Media(mediaUrl), play: false);
      await _player!.setVolume(0);
      await _player!.setPlaylistMode(PlaylistMode.loop);
      await _player!.play();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      debugPrint('WaitingVideoWidget init: $e');
    }
  }

  @override
  void dispose() {
    final p = _player;
    _player = null;
    _controller = null;
    if (p != null) {
      p.stop().then((_) => Future.delayed(const Duration(milliseconds: 250)))
          .then((_) => p.dispose())
          .catchError((_) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _controller == null) {
      return const ColoredBox(color: Colors.black87);
    }
    return ColoredBox(
      color: Colors.black,
      child: Video(
        controller: _controller!,
        fit: BoxFit.cover,
      ),
    );
  }
}
