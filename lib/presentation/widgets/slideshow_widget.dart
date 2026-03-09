import 'dart:io' as io;

import 'package:flutter/material.dart';

import '../../core/storage/rom_media_storage.dart';
import '../../data/models/media_item_model.dart';
import '../controllers/slideshow_controller.dart';
import 'media_image_widget.dart';
import 'media_video_widget.dart';
import 'sdp/media_sdp_widget.dart';

/// Fade transition giữa 2 layer (200ms).
const Duration _kFadeDuration = Duration(milliseconds: 200);

/// Slideshow: Controller quản lý preload. UI chỉ render.
/// Double buffer: 2 layer (current + next), fade khi chuyển, evict ảnh cũ.
class SlideshowWidget extends StatefulWidget {
  const SlideshowWidget({super.key});

  @override
  State<SlideshowWidget> createState() => _SlideshowWidgetState();
}

class _SlideshowWidgetState extends State<SlideshowWidget> {
  late final SlideshowController _controller;

  List<MediaItem> _items = [];
  int _currentIndex = 0;
  int _visibleLayer = 0;

  @override
  void initState() {
    super.initState();

    _controller = SlideshowController(
      onMediaChanged: _onMediaChanged,
      getDisplayUrl: _displayUrl,
      onPreloadImage: (url) {
        if (!mounted) return;
        if (url.startsWith('/') || _isFilePath(url)) {
          precacheImage(FileImage(io.File(url)), context).catchError((_) {});
        } else if (!url.startsWith('asset:')) {
          precacheImage(NetworkImage(url), context).catchError((_) {});
        }
      },
      onPreloadVideo: (_) {
        // Preload video = chỉ check file; không open player. Chỉ open khi play.
      },
      onReleaseImage: (url) {
        if (!mounted) return;
        try {
          if (url.startsWith('/') || io.File(url).existsSync()) {
            PaintingBinding.instance.imageCache.evict(FileImage(io.File(url)));
          } else if (url.startsWith('http')) {
            PaintingBinding.instance.imageCache.evict(NetworkImage(url));
          }
        } catch (_) {}
      },
    );

    _controller.init();
  }

  bool _isFilePath(String url) {
    if (url.isEmpty) return false;
    if (url.startsWith('http')) return false;
    return io.File(url).existsSync();
  }

  String _displayUrl(MediaItem item) {
    final lp = item.localPath;
    if (lp != null && lp.isNotEmpty && !lp.startsWith('/')) {
      final full = RomMediaStorage.I.fullPath(lp);
      if (full != null) return full;
    }
    return item.playbackUrl;
  }

  void _onMediaChanged(MediaItem? current, int index, List<MediaItem> all) {
    if (!mounted) return;
    setState(() {
      final prevCount = _items.length;
      _items = all;
      final newIndex = index;
      final n = _items.length;

      if (n == 0) return;

      if (prevCount == 0 || n < 2) {
        _currentIndex = newIndex;
        _visibleLayer = 0;
        return;
      }

      _currentIndex = newIndex;
      _visibleLayer = 1 - _visibleLayer;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _buildContent(),
        if (_items.isNotEmpty && _items[_currentIndex].type != MediaType.sdp)
          _buildPageIndicator(),
      ],
    );
  }

  Widget _buildContent() {
    if (_items.isEmpty) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
        ),
      );
    }

    final n = _items.length;
    if (n < 2) {
      return RepaintBoundary(
        key: ValueKey('slide-$_currentIndex-${_items[_currentIndex].id}'),
        child: _buildMediaItem(_items[_currentIndex]),
      );
    }

    final layer0Index = _visibleLayer == 0 ? _currentIndex : (_currentIndex + 1) % n;
    final layer1Index = _visibleLayer == 1 ? _currentIndex : (_currentIndex + 1) % n;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: AnimatedOpacity(
            duration: _kFadeDuration,
            opacity: _visibleLayer == 0 ? 1 : 0,
            child: RepaintBoundary(
              key: ValueKey('layer0-$layer0Index-${_items[layer0Index].id}'),
              child: _buildMediaItem(_items[layer0Index]),
            ),
          ),
        ),
        Positioned.fill(
          child: AnimatedOpacity(
            duration: _kFadeDuration,
            opacity: _visibleLayer == 1 ? 1 : 0,
            child: RepaintBoundary(
              key: ValueKey('layer1-$layer1Index-${_items[layer1Index].id}'),
              child: _buildMediaItem(_items[layer1Index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMediaItem(MediaItem item) {
    final url = _displayUrl(item);
    switch (item.type) {
      case MediaType.image:
        return MediaImageWidget(url: url);
      case MediaType.video:
        return MediaVideoWidget(
          url: url,
          onVideoStarted: _controller.notifyVideoStarted,
          onVideoEnded: _controller.notifyVideoEnded,
        );
      case MediaType.sdp:
        return MediaSdpWidget(
          posterUrl: item.url.isNotEmpty ? item.url : null,
          backgroundAsset: item.sdpBackgroundAsset,
        );
    }
  }

  Widget _buildPageIndicator() {
    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${_currentIndex + 1}/${_items.length}',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
      ),
    );
  }
}
