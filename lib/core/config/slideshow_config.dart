import 'package:flutter/foundation.dart';

/// Config để toggle các thành phần slideshow

class SlideshowConfig extends ChangeNotifier {
  SlideshowConfig._();
  static final SlideshowConfig I = SlideshowConfig._();

  // ============ Toggle switches ============

  bool _enablePoster = true;
  bool _enableSdp = true;
  bool _enableVideo = true;
  bool _enableAudio = true;
  bool _enableLocalAssets = true; // Dùng video/poster từ assets

  /// Hiển thị poster từ API
  bool get enablePoster => _enablePoster;
  set enablePoster(bool value) {
    _enablePoster = value;
    notifyListeners();
  }

  /// Hiển thị SDP (Special Dynamic Poster)
  bool get enableSdp => _enableSdp;
  set enableSdp(bool value) {
    _enableSdp = value;
    notifyListeners();
  }

  /// Hiển thị video
  bool get enableVideo => _enableVideo;
  set enableVideo(bool value) {
    _enableVideo = value;
    notifyListeners();
  }

  /// Phát nhạc nền
  bool get enableAudio => _enableAudio;
  set enableAudio(bool value) {
    _enableAudio = value;
    notifyListeners();
  }

  /// Sử dụng video/poster từ assets thay vì API
  bool get enableLocalAssets => _enableLocalAssets;
  set enableLocalAssets(bool value) {
    _enableLocalAssets = value;
    notifyListeners();
  }

  // ============ Asset paths ============

  /// Path nhạc nền
  String backgroundMusicPath = 'assets/emlakothe.mp3';

  /// Path video local (test)
  String localVideoPath = 'assets/catoon.mp4';

  /// Duration mặc định cho video (giây)
  int videoDurationSeconds = 30;

  // ============ Helper methods ============

  /// xem SDP
  void onlySdp() {
    _enablePoster = false;
    _enableSdp = true;
    _enableVideo = false;
    _enableAudio = false;
    notifyListeners();
  }

  /// xem Poster
  void onlyPoster() {
    _enablePoster = true;
    _enableSdp = false;
    _enableVideo = false;
    _enableAudio = false;
    notifyListeners();
  }

  /// Chỉ xem Video (tắt hết còn lại)
  void onlyVideo() {
    _enablePoster = false;
    _enableSdp = false;
    _enableVideo = true;
    _enableAudio = false;
    notifyListeners();
  }

  /// Bật tất cả
  void enableAll() {
    _enablePoster = true;
    _enableSdp = true;
    _enableVideo = true;
    _enableAudio = true;
    notifyListeners();
  }

  /// Tắt tất cả
  void disableAll() {
    _enablePoster = false;
    _enableSdp = false;
    _enableVideo = false;
    _enableAudio = false;
    notifyListeners();
  }

  /// Reset về mặc định
  void reset() {
    _enablePoster = true;
    _enableSdp = true;
    _enableVideo = true;
    _enableAudio = true;
    _enableLocalAssets = true;
    notifyListeners();
  }

  @override
  String toString() {
    return 'SlideshowConfig('
        'poster: $_enablePoster, '
        'sdp: $_enableSdp, '
        'video: $_enableVideo, '
        'audio: $_enableAudio, '
        'localAssets: $_enableLocalAssets)';
  }
}
