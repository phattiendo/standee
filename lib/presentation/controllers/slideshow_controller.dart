import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/audio/background_audio_service.dart';
import '../../core/config/slideshow_config.dart';
import '../../core/constants/api_constants.dart';
import '../../core/connectivity/connectivity_service.dart';
import '../../core/storage/rom_media_storage.dart';
import '../../data/models/media_item_model.dart';
import '../../data/repositories/media_repository.dart';

/// Controller sở hữu toàn bộ logic: preload (image + video), release (image).
/// Image/SDP: timer(durationSeconds) → nextSlide().
/// Video: không dùng timer → chỉ nextSlide() khi onVideoEnded.
/// UI chỉ render + thực thi preload/release khi controller gọi callback.
class SlideshowController {
  SlideshowController({
    MediaRepository? repository,
    this.onMediaChanged,
    this.onPreloadImage,
    this.onPreloadVideo,
    this.onReleaseImage,
    this.getDisplayUrl,
  }) : _repository = repository ?? MediaRepository();

  final MediaRepository _repository;
  final _config = SlideshowConfig.I;

  final void Function(MediaItem? current, int index, List<MediaItem> all)? onMediaChanged;
  final void Function(String imageUrl)? onPreloadImage;
  final void Function(String displayUrl)? onPreloadVideo;
  final void Function(String imageUrl)? onReleaseImage;
  final String? Function(MediaItem item)? getDisplayUrl;

  final List<MediaItem> _media = [];
  int _currentIndex = 0;
  Timer? _timer;
  StreamSubscription<bool>? _connectivitySub;

  bool _initialized = false;

  static const int _videoFallbackSeconds = 7200;

  DateTime? _lastRefreshTime;
  static const Duration _refreshInterval = Duration(minutes: 15);

  MediaItem? get current => _media.isEmpty ? null : _media[_currentIndex % _media.length];

  MediaItem? get next {
    if (_media.length < 2) return null;
    return _media[(_currentIndex + 1) % _media.length];
  }

  List<MediaItem> get media => List.unmodifiable(_media);
  int get currentIndex => _currentIndex;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    debugPrint('SlideshowController: init started');
    await RomMediaStorage.I.ensureDir();

    _buildMediaList([]);
    _notify();
    debugPrint('SlideshowController: initial notify with ${_media.length} items');

    _startTimer();

    if (_config.enableAudio) {
      await RomMediaStorage.I.copyAssetToRomOnce(_config.backgroundMusicPath);
      unawaited(BackgroundAudioService.I.init(
        assetPath: _config.backgroundMusicPath,
        filePath: RomMediaStorage.I.backgroundMusicRomPath,
      ));
    }

    unawaited(_initRepository());
    _config.addListener(_onConfigChanged);
  }

  Future<void> _initRepository() async {
    try {
      await _repository.init();
      await ConnectivityService.I.init();

      _connectivitySub = ConnectivityService.I.onStatusChanged.listen((online) {
        if (online) _refresh();
      });

      if (_config.enableVideo && _config.enableLocalAssets) {
        await RomMediaStorage.I.copyAssetToRomOnce(_config.localVideoPath);
      }

      final cached = await _repository.loadInitial();
      if (cached.isNotEmpty) {
        if (_config.enableVideo && _config.enableLocalAssets) {
          await RomMediaStorage.I.copyAssetToRomOnce(_config.localVideoPath);
        }
        _buildMediaList(cached);
        if (_currentIndex >= _media.length) _currentIndex = 0;
        _notify();
        preloadNext();
        _startTimer();
        unawaited(_refresh());
      } else {
        await _refresh();
      }
    } catch (e) {
      debugPrint('Repository init error: $e');
    }
  }

  void _onConfigChanged() {
    if (_config.enableVideo && _config.enableLocalAssets) {
      unawaited(RomMediaStorage.I.copyAssetToRomOnce(_config.localVideoPath)
          .then((_) => _rebuildMediaList()));
    } else {
      _rebuildMediaList();
    }
    BackgroundAudioService.I.enabled = _config.enableAudio;
  }

  void _rebuildMediaList() {
    final apiItems = _media
        .where((item) {
          if (item.type == MediaType.sdp) return false;
          if (item.type == MediaType.video &&
              (item.url.startsWith('asset:') || item.url == _config.localVideoPath)) {
            return false;
          }
          return true;
        })
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

    if (_config.enablePoster) {
      _media.addAll(apiItems.where((item) => item.type == MediaType.image));
    }

    if (_config.enableVideo) {
      _media.addAll(apiItems.where((item) => item.type == MediaType.video));

      if (_config.enableLocalAssets) {
        final romPath = RomMediaStorage.I.localVideoRomPath;
        if (romPath != null) {
          _media.add(MediaItem.video(
            url: _config.localVideoPath,
            durationSeconds: _config.videoDurationSeconds,
          ).copyWith(localPath: romPath));
        } else {
          _media.add(MediaItem.video(
            url: 'asset:${_config.localVideoPath}',
            durationSeconds: _config.videoDurationSeconds,
          ));
        }
      }
    }

    if (_media.isEmpty) {
      _media.add(_createSdpItem());
    }

    debugPrint('Built media list: ${_media.length} items');
  }

  MediaItem _createSdpItem({String? posterUrl}) {
    return MediaItem.sdp(
      id: 'sdp',
      durationSeconds: ApiConstants.sdpDurationSeconds,
      posterUrl: posterUrl,
      backgroundAsset: ApiConstants.sdpDefaultBackground,
    );
  }

  /// Timer chỉ cho image/SDP. Video không dùng timer — chuyển slide chỉ khi onVideoEnded.
  void _startTimer() {
    _timer?.cancel();
    if (_media.isEmpty) return;

    final currentItem = current;
    if (currentItem == null) return;

    final isVideo = currentItem.type == MediaType.video;
    final duration = isVideo ? _videoFallbackSeconds : currentItem.durationSeconds;

    _timer = Timer(Duration(seconds: duration), _onSlideTimerFired);
  }

  void _onSlideTimerFired() {
    if (_media.isEmpty) return;
    nextSlide();
  }

  /// Giải phóng tài nguyên slide cũ (image → evict cache; video không open nên không release).
  void releasePrevious(MediaItem? prevItem) {
    if (prevItem == null) return;
    if (prevItem.type == MediaType.image) {
      final url = getDisplayUrl?.call(prevItem) ?? prevItem.playbackUrl;
      if (url.isNotEmpty) onReleaseImage?.call(url);
    }
  }

  /// Chuyển sang slide tiếp theo. Gọi từ timer (image/SDP) hoặc từ onVideoEnded (video).
  void nextSlide() {
    _timer?.cancel();
    if (_media.isEmpty) return;

    final prevItem = current;
    _currentIndex = (_currentIndex + 1) % _media.length;
    final nextItem = current;

    releasePrevious(prevItem);
    _handleAudioTransition(prevItem, nextItem);
    _notify();
    preloadNext();
    _startTimer();
  }

  /// Preload slide kế tiếp: image = precache, video = chỉ kiểm tra file (không open player).
  void preloadNext() {
    final nextItem = next;
    if (nextItem == null) return;

    final displayUrl = getDisplayUrl?.call(nextItem) ?? nextItem.playbackUrl;
    if (displayUrl.isEmpty) return;

    if (nextItem.type == MediaType.image && !nextItem.playbackUrl.startsWith('asset:')) {
      onPreloadImage?.call(displayUrl);
    } else if (nextItem.type == MediaType.video) {
      onPreloadVideo?.call(displayUrl);
    }
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

  /// Video bắt đầu phát → chỉ tắt nhạc nền. Không dùng timer; chuyển slide khi videoEnded.
  void notifyVideoStarted() {
    if (_config.enableAudio) {
      BackgroundAudioService.I.fadeOutAndPause();
    }
  }

  /// Video kết thúc → chuyển slide (video không dùng timer).
  void notifyVideoEnded() {
    if (_config.enableAudio) {
      BackgroundAudioService.I.resumeAndFadeIn();
    }
    nextSlide();
  }

  Future<void> _refresh() async {
    if (_lastRefreshTime != null &&
        DateTime.now().difference(_lastRefreshTime!) < _refreshInterval) {
      return;
    }
    _lastRefreshTime = DateTime.now();

    try {
      final newList = await _repository.checkVersionAndUpdateIfNeeded();
      if (newList == null || newList.isEmpty) return;

      if (_config.enableVideo && _config.enableLocalAssets) {
        await RomMediaStorage.I.copyAssetToRomOnce(_config.localVideoPath);
      }
      final wasAtSdp = current?.type == MediaType.sdp;
      _buildMediaList(newList);
      if (wasAtSdp && _config.enableSdp && _media.isNotEmpty) {
        _currentIndex = 0;
      } else if (_currentIndex >= _media.length) {
        _currentIndex = 0;
      }
      _notify();
      preloadNext();
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
