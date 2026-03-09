import 'dart:async';

import 'package:flutter/foundation.dart';

import '../connectivity/connectivity_service.dart';
import '../config/slideshow_config.dart';
import '../storage/rom_media_storage.dart';
import '../../data/models/media_item_model.dart';
import '../../data/repositories/media_repository.dart';

/// Kết quả bootstrap (init + first load)
class BootstrapResult {
  final bool hasData;
  final bool isOffline;
  final bool needsSetup;
  final String? errorMessage;

  const BootstrapResult({
    required this.hasData,
    required this.isOffline,
    this.needsSetup = false,
    this.errorMessage,
  });
}

/// Chạy init app: repository, connectivity, first data load.
/// AppBloc gọi khi AppStarted / AppRetryRequested.
class AppBootstrap {
  AppBootstrap({
    MediaRepository? repository,
  }) : _repository = repository ?? MediaRepository();

  final MediaRepository _repository;

  Future<BootstrapResult> run() async {
    debugPrint('AppBootstrap: run started');

    try {
      await _repository.init();
      await ConnectivityService.I.init();

      // Ưu tiên ROM: load từ cache trước (nhanh)
      final cached = await _repository.loadInitial();

      // Đã có data trong ROM → vào màn hình ngay, refresh API chạy nền
      if (cached.isNotEmpty) {
        debugPrint('AppBootstrap: using ${cached.length} items from ROM');
        unawaited(_refreshInBackground());
        return const BootstrapResult(hasData: true, isOffline: false);
      }

      // Chưa có cache → copy video chờ vào ROM trước (để màn cài đặt phát từ ROM), rồi báo cần setup
      await RomMediaStorage.I.copyAssetToRomOnce('assets/catoon1.mp4');
      return const BootstrapResult(
        hasData: false,
        isOffline: false,
        needsSetup: true,
      );
    } catch (e, st) {
      debugPrint('AppBootstrap error: $e');
      debugPrint('$st');
      return BootstrapResult(
        hasData: false,
        isOffline: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> _refreshInBackground() async {
    try {
      await _repository.refreshFromRemote().timeout(
        const Duration(seconds: 30),
        onTimeout: () => <MediaItem>[],
      );
    } catch (_) {}
  }

  /// Cài đặt lần đầu: copy asset (video, nhạc) vào ROM + gọi API tải media vào ROM.
  /// Gọi khi [BootstrapResult.needsSetup] == true. [onProgress] nhận (0.0..1.0, message).
  /// Cài đặt lần đầu: mọi thứ (video, nhạc, ảnh/video từ API) đều lưu vào ROM.
  Future<void> runFirstTimeSetup(
    void Function(double progress, String message) onProgress,
  ) async {
    final config = SlideshowConfig.I;
    onProgress(0.0, 'Copy video vào ROM...');
    if (config.localVideoPath.isNotEmpty) {
      await RomMediaStorage.I.copyAssetToRomOnce(config.localVideoPath);
    }
    onProgress(0.2, 'Copy nhạc nền vào ROM...');
    if (config.backgroundMusicPath.isNotEmpty) {
      await RomMediaStorage.I.copyAssetToRomOnce(config.backgroundMusicPath);
    }
    onProgress(0.3, 'Tải ảnh/video từ server...');
    try {
      await _repository.refreshFromRemote().timeout(
        const Duration(minutes: 5),
        onTimeout: () => <MediaItem>[],
      );
    } catch (e) {
      debugPrint('AppBootstrap runFirstTimeSetup refresh: $e');
    }
    onProgress(1.0, 'Đã lưu tất cả vào ROM');
  }
}
