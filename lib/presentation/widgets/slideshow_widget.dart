import 'package:flutter/material.dart';

import '../../core/config/slideshow_config.dart';
import '../../data/models/media_item_model.dart';
import '../controllers/slideshow_controller.dart';
import 'media_image_widget.dart';
import 'media_video_widget.dart';
import 'sdp/liquid_glass_container.dart';
import 'sdp/media_sdp_widget.dart';

class SlideshowWidget extends StatefulWidget {
  const SlideshowWidget({super.key});

  @override
  State<SlideshowWidget> createState() => _SlideshowWidgetState();
}

class _SlideshowWidgetState extends State<SlideshowWidget> {
  late final SlideshowController _controller;

  List<MediaItem> _items = [];
  int _currentIndex = 0;
  
  // Flag để delay khi chuyển từ video
  bool _transitioningFromVideo = false;
  MediaItem? _previousItem;

  @override
  void initState() {
    super.initState();

    _controller = SlideshowController(
      onMediaChanged: _onMediaChanged,
      onPreloadImage: (url) {
        if (mounted && !url.startsWith('asset:')) {
          precacheImage(NetworkImage(url), context).catchError((_) {});
        }
      },
    );

    _controller.init();

    SlideshowConfig.I.addListener(_onConfigChanged);
  }

  void _onMediaChanged(MediaItem? current, int index, List<MediaItem> all) {
    if (!mounted) return;
    
    final wasVideo = _previousItem?.type == MediaType.video;
    final isVideo = current?.type == MediaType.video;
    
    // Nếu chuyển TỪ video sang media khác, cần delay
    if (wasVideo && !isVideo) {
      _transitioningFromVideo = true;
      setState(() {});
      
      // Delay 400ms cho MediaCodec release
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          setState(() {
            _transitioningFromVideo = false;
            _items = all;
            _currentIndex = index;
            _previousItem = current;
          });
        }
      });
    } else {
      setState(() {
        _items = all;
        _currentIndex = index;
        _previousItem = current;
      });
    }
  }

  void _onConfigChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    SlideshowConfig.I.removeListener(_onConfigChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Main content
        _buildContent(),

        // Page indicator
        if (_items.isNotEmpty && 
            !_transitioningFromVideo &&
            _items[_currentIndex].type != MediaType.sdp)
          _buildPageIndicator(),

        // Debug panel
        if (_showDebugPanel) _buildDebugPanel(),
      ],
    );
  }

  // Đặt false khi release
  bool get _showDebugPanel => true;

  Widget _buildContent() {
    // Hiện loading khi đang transition từ video
    if (_transitioningFromVideo) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white30,
          ),
        ),
      );
    }
    
    if (_items.isEmpty) {
      return const _LoadingState();
    }

    final current = _items[_currentIndex];

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: KeyedSubtree(
        key: ValueKey('${current.type}-$_currentIndex-${current.url.hashCode}'),
        child: _buildMediaItem(current),
      ),
    );
  }

  Widget _buildMediaItem(MediaItem item) {
    switch (item.type) {
      case MediaType.image:
        return MediaImageWidget(url: item.url);
      case MediaType.video:
        return MediaVideoWidget(
          url: item.url,
          onVideoStarted: _controller.notifyVideoStarted,
          onVideoEnded: _controller.notifyVideoEnded,
        );
      case MediaType.sdp:
        return MediaSdpWidget(
          posterUrl: item.url.isNotEmpty ? item.url : null,
          backgroundAsset: item.sdpBackgroundAsset,
          glassType: GlassType.backdrop,
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

  Widget _buildDebugPanel() {
    final config = SlideshowConfig.I;

    return Positioned(
      top: 50,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Debug', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            _buildSwitch('SDP', config.enableSdp, (v) => config.enableSdp = v),
            _buildSwitch('Poster', config.enablePoster, (v) => config.enablePoster = v),
            _buildSwitch('Video', config.enableVideo, (v) => config.enableVideo = v),
            _buildSwitch('Audio', config.enableAudio, (v) => config.enableAudio = v),
            const SizedBox(height: 4),
            _buildBtn('Only SDP', config.onlySdp),
            _buildBtn('Only Video', config.onlyVideo),
            _buildBtn('All ON', config.enableAll),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitch(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 50, child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 10))),
        SizedBox(
          height: 20,
          width: 36,
          child: Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: Colors.green,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ],
    );
  }

  Widget _buildBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
        child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9)),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
      ),
    );
  }
}
