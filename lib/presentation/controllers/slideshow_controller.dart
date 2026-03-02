import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/audio/background_audio_service.dart';
import '../../core/config/slideshow_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../data/models/media_item_model.dart';
import '../../data/repositories/media_repository.dart';

/// Controller quản lý slideshow + audio
class SlideshowController {
  SlideshowController({
    MediaRepository? repository,
    this.onMediaChanged,
    this.onPreloadImage,
  }) : _repository = repository ?? MediaRepository();

  final MediaRepository _repository;
  final _config = SlideshowConfig.I;

  final void Function(MediaItem? current, int index, List<MediaItem> all)? onMediaChanged;
  final void Function(String imageUrl)? onPreloadImage;

  final List<MediaItem> _media = [];
  int _currentIndex = 0;
  Timer? _timer;
  StreamSubscription<bool>? _connectivitySub;

  bool _initialized = false;

  MediaItem? get current => _media.isEmpty ? null : _media[_currentIndex % _media.length];

  MediaItem? get next {
    if (_media.length < 2) return null;
    return _media[(_currentIndex + 1) % _media.length];
  }

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    debugPrint('SlideshowController: init started');

    // 1. Build SDP ngay để có gì đó hiển thị
    _buildMediaList([]);
    _notify();
    debugPrint('SlideshowController: initial notify with ${_media.length} items');

    // 2. Start timer
    _startTimer();

    // 3. Init audio KHÔNG AWAIT - chạy background
    if (_config.enableAudio) {
      unawaited(BackgroundAudioService.I.init(assetPath: _config.backgroundMusicPath));
    }

    // 4. Init repository background
    unawaited(_initRepository());

    // 5. Listen config
    _config.addListener(_onConfigChanged);
  }

  Future<void> _initRepository() async {
    try {
      await _repository.init();
      await ConnectivityService.I.init();

      _connectivitySub = ConnectivityService.I.onStatusChanged.listen((online) {
        if (online) _refresh();
      });

      // Fetch data
      await _refresh();
    } catch (e) {
      debugPrint('Repository init error: $e');
    }
  }

  void _onConfigChanged() {
    _rebuildMediaList();
    BackgroundAudioService.I.enabled = _config.enableAudio;
  }

  void _rebuildMediaList() {
    final apiItems = _media
        .where((item) =>
            item.type != MediaType.sdp &&
            !(item.type == MediaType.video && item.url.startsWith('asset:')))
        .toList();

    _buildMediaList(apiItems);

    if (_currentIndex >= _media.length) {
      _currentIndex = 0;
    }

    _notify();
    _startTimer();
  }

  void _buildMediaList(List<MediaItem> apiItems) {
    _media.clear();

    // 1. SDP
    if (_config.enableSdp) {
      String? firstPosterUrl;
      for (final item in apiItems) {
        if (item.type == MediaType.image && item.url.isNotEmpty) {
          firstPosterUrl = item.url;
          break;
        }
      }
      _media.add(_createSdpItem(posterUrl: firstPosterUrl));
    }

    // 2. Posters
    if (_config.enablePoster) {
      _media.addAll(apiItems.where((item) => item.type == MediaType.image));
    }

    // 3. Videos
    if (_config.enableVideo) {
      _media.addAll(apiItems.where((item) => item.type == MediaType.video));

      if (_config.enableLocalAssets) {
        _media.add(MediaItem.video(
          url: 'asset:${_config.localVideoPath}',
          durationSeconds: _config.videoDurationSeconds,
        ));
      }
    }

    // Fallback
    if (_media.isEmpty) {
      _media.add(_createSdpItem());
    }

    debugPrint('Built media list: ${_media.length} items');
  }

  MediaItem _createSdpItem({String? posterUrl}) {
    return MediaItem.sdp(
      durationSeconds: ApiConstants.sdpDurationSeconds,
      posterUrl: posterUrl,
      backgroundAsset: ApiConstants.sdpDefaultBackground,
    );
  }

  void _startTimer() {
    _timer?.cancel();
    if (_media.isEmpty) return;

    void scheduleNext() {
      final currentItem = current;
      if (currentItem == null) return;

      _timer = Timer(Duration(seconds: currentItem.durationSeconds), () {
        if (_media.isEmpty) return;

        final prevItem = current;
        _currentIndex = (_currentIndex + 1) % _media.length;
        final nextItem = current;

        _handleAudioTransition(prevItem, nextItem);
        _notify();
        _requestPreloadNext();
        scheduleNext();
      });
    }

    scheduleNext();
  }

  void _handleAudioTransition(MediaItem? from, MediaItem? to) {
    if (!_config.enableAudio) return;

    final wasVideo = from?.type == MediaType.video;
    final isVideo = to?.type == MediaType.video;

    if (!wasVideo && isVideo) {
      BackgroundAudioService.I.fadeOutAndPause();
    } else if (wasVideo && !isVideo) {
      BackgroundAudioService.I.resumeAndFadeIn();
    }
  }

  void notifyVideoStarted() {
    if (_config.enableAudio) {
      BackgroundAudioService.I.fadeOutAndPause();
    }
  }

  void notifyVideoEnded() {
    if (_config.enableAudio) {
      BackgroundAudioService.I.resumeAndFadeIn();
    }
  }

  void _requestPreloadNext() {
    final nextItem = next;
    if (nextItem != null &&
        nextItem.type == MediaType.image &&
        !nextItem.url.startsWith('asset:')) {
      onPreloadImage?.call(nextItem.url);
    }
  }

  Future<void> _refresh() async {
    try {
      final remote = await _repository.refreshFromRemote();
      final wasAtSdp = current?.type == MediaType.sdp;

      _buildMediaList(remote);

      if (wasAtSdp && _config.enableSdp && _media.isNotEmpty) {
        _currentIndex = 0;
      } else if (_currentIndex >= _media.length) {
        _currentIndex = 0;
      }

      _notify();
      _requestPreloadNext();
      _startTimer();
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  void _notify() {
    onMediaChanged?.call(current, _currentIndex, _media);
  }

  void dispose() {
    _timer?.cancel();
    _connectivitySub?.cancel();
    _config.removeListener(_onConfigChanged);
  }
}
