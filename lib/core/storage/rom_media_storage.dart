import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../../data/models/media_item_model.dart';
import '../network/dio_client.dart';

/// Thông tin file để LRU eviction.
class _FileEntry {
  final File file;
  final DateTime modified;
  final int size;
  const _FileEntry({
    required this.file,
    required this.modified,
    required this.size,
  });
}

/// Cấu trúc ROM: standee_media/images/, videos/, audio/, cache/.
/// Asset copy 1 lần → videos/ hoặc audio/ (tên cố định). Download → cache/ → move sang images/ hoặc videos/.
/// LRU chỉ xóa trong cache/ và file không phải asset cố định.
class RomMediaStorage {
  RomMediaStorage._();
  static final RomMediaStorage I = RomMediaStorage._();

  static const String _dirName = 'standee_media';
  static const String _imagesDir = 'images';
  static const String _videosDir = 'videos';
  static const String _audioDir = 'audio';
  static const String _cacheDir = 'cache';

  static const int _maxCacheBytes = 500 * 1024 * 1024; // ~500MB
  static const int _copyChunkBytes = 512 * 1024; // 512KB chunk
  String? _rootPath;

  /// Path ROM đã copy (asset → ROM). Luôn play từ file, không rootBundle.
  String? _localVideoRomPath;
  String? get localVideoRomPath => _localVideoRomPath;

  String? _setupWaitingVideoRomPath;
  String? get setupWaitingVideoRomPath => _setupWaitingVideoRomPath;

  String? _backgroundMusicRomPath;
  String? get backgroundMusicRomPath => _backgroundMusicRomPath;

  /// Root path (sync sau lần gọi rootPath đầu). Để resolve relative localPath → full path.
  String? get rootPathSync => _rootPath;

  Future<String> get rootPath async {
    final p = (await getApplicationDocumentsDirectory()).path;
    _rootPath ??= '$p/$_dirName';
    return _rootPath!;
  }

  /// Full path cho relative localPath (vd. images/poster1.jpg).
  String? fullPath(String relativePath) {
    if (relativePath.isEmpty) return null;
    final root = _rootPath;
    if (root == null) return null;
    if (relativePath.startsWith('/')) return relativePath;
    return '$root/$relativePath';
  }

  Future<void> ensureDir() async {
    final base = await rootPath;
    for (final sub in [_imagesDir, _videosDir, _audioDir, _cacheDir]) {
      final dir = Directory('$base/$sub');
      if (!await dir.exists()) await dir.create(recursive: true);
    }
  }

  void _setRomPathFromAsset(String assetPath, String filePath) {
    if (assetPath.contains('Cat playing') || assetPath.toLowerCase().contains('cat_playing')) {
      _setupWaitingVideoRomPath = filePath;
    } else if (assetPath.toLowerCase().endsWith('.mp3')) {
      _backgroundMusicRomPath = filePath;
    } else if (assetPath.toLowerCase().endsWith('.mp4')) {
      _localVideoRomPath = filePath;
    }
  }

  /// Copy 1 lần asset → ROM vào subdir (videos/ hoặc audio/). Chunk 512KB. Sau đó luôn play từ file.
  Future<String?> copyAssetToRomOnce(String assetPath) async {
    final path = assetPath.startsWith('/') ? assetPath.substring(1) : assetPath;
    if (path.isEmpty || !path.startsWith('assets/')) return null;
    try {
      await ensureDir();
      final base = await rootPath;
      final lower = path.toLowerCase();
      final String subdir;
      final String fileName;
      if (lower.endsWith('.mp3')) {
        subdir = _audioDir;
        fileName = path.split('/').last.replaceAll(' ', '_');
      } else if (lower.endsWith('.mp4') || lower.endsWith('.webm')) {
        subdir = _videosDir;
        if (path.contains('Cat playing')) {
          fileName = 'cat_playing.mp4';
        } else {
          fileName = path.split('/').last.replaceAll(' ', '_');
        }
      } else {
        return null;
      }
      final filePath = '$base/$subdir/$fileName';
      final file = File(filePath);
      if (await file.exists()) {
        _setRomPathFromAsset(path, filePath);
        return filePath;
      }
      // rootBundle.load() load toàn bộ file vào RAM — file lớn (vd. video 100MB+) dễ gây OOM khi cài mới.
      final byteData = await rootBundle.load(path);
      final total = byteData.lengthInBytes;
      final sink = file.openWrite();
      for (var offset = 0; offset < total; offset += _copyChunkBytes) {
        final len = (offset + _copyChunkBytes > total) ? total - offset : _copyChunkBytes;
        sink.add(byteData.buffer.asUint8List(byteData.offsetInBytes + offset, len));
      }
      await sink.close();
      _setRomPathFromAsset(path, filePath);
      debugPrint('RomMediaStorage: asset -> ROM $subdir/$fileName (${(total / 1024 / 1024).toStringAsFixed(1)}MB)');
      return filePath;
    } catch (e) {
      debugPrint('RomMediaStorage copyAssetToRomOnce error: $e');
      return null; // Tránh crash khi load/copy lỗi (OOM, asset không tồn tại)
    }
  }

  /// Tải file từ URL: stream vào cache/file.tmp → xong move sang images/ hoặc videos/.
  /// [relativePath] ví dụ images/poster1.jpg, videos/promo1.mp4.
  Future<String?> downloadToRom(String url, String relativePath) async {
    if (url.isEmpty ||
        url.startsWith('asset:') ||
        (!url.startsWith('http://') && !url.startsWith('https://'))) {
      return null;
    }
    try {
      await ensureDir();
      final base = await rootPath;
      final cacheFile = File('$base/$_cacheDir/${relativePath.replaceAll('/', '_')}.tmp');
      if (cacheFile.existsSync()) await cacheFile.delete();

      final response = await DioClient.I.client.get<ResponseBody>(
        url,
        options: Options(responseType: ResponseType.stream),
      );
      final stream = response.data?.stream;
      if (stream == null) return null;

      final sink = cacheFile.openWrite();
      int received = 0;
      await for (final chunk in stream) {
        sink.add(chunk);
        received += chunk.length;
      }
      await sink.close();
      if (received == 0) {
        await cacheFile.delete().catchError((_) => cacheFile);
        return null;
      }

      final dir = Directory('$base/${relativePath.split('/').first}');
      if (!await dir.exists()) await dir.create(recursive: true);
      final destFile = File('$base/$relativePath');
      if (destFile.existsSync()) await destFile.delete();
      await cacheFile.rename(destFile.path);
      await _enforceCacheQuota();
      debugPrint('RomMediaStorage: downloaded -> $relativePath (${(received / 1024 / 1024).toStringAsFixed(1)}MB)');
      return relativePath;
    } catch (e) {
      debugPrint('RomMediaStorage download error ($url): $e');
      return null;
    }
  }

  /// Tải ảnh: download → resize max 1920 nếu cần → lưu images/id.ext.
  Future<String?> downloadImageToRom(String url, String id, String extension) async {
    final rel = '$_imagesDir/${id}_${url.hashCode.abs()}$extension';
    final bytes = await _downloadBytes(url);
    if (bytes == null || bytes.isEmpty) return null;
    final resized = await _resizeImageIfNeeded(bytes, 1920);
    if (resized == null || resized.isEmpty) return null;
    try {
      await ensureDir();
      final base = await rootPath;
      final filePath = '$base/$rel';
      await File(filePath).writeAsBytes(resized);
      await _enforceCacheQuota();
      return rel;
    } catch (e) {
      debugPrint('RomMediaStorage downloadImageToRom error: $e');
      return null;
    }
  }

  Future<List<int>?> _downloadBytes(String url) async {
    try {
      final response = await DioClient.I.client.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      return response.data;
    } catch (_) {
      return null;
    }
  }

  Future<Uint8List?> _resizeImageIfNeeded(List<int> bytes, int maxSize) async {
    try {
      final image = img.decodeImage(Uint8List.fromList(bytes));
      if (image == null) return Uint8List.fromList(bytes);
      final w = image.width;
      final h = image.height;
      if (w <= maxSize && h <= maxSize) return Uint8List.fromList(bytes);
      final scale = (w > h) ? maxSize / w : maxSize / h;
      final nw = (w * scale).round().clamp(1, maxSize);
      final nh = (h * scale).round().clamp(1, maxSize);
      final resized = img.copyResize(image, width: nw, height: nh);
      return img.encodeJpg(resized, quality: 85);
    } catch (_) {
      return Uint8List.fromList(bytes);
    }
  }

  /// Tải video: stream vào cache rồi move sang videos/. Không resize.
  Future<String?> downloadVideoToRom(String url, String id) async {
    final ext = _extensionFromUrl(url);
    final rel = '$_videosDir/${id}_${url.hashCode.abs()}$ext';
    return downloadToRom(url, rel);
  }

  /// Tải toàn bộ list: image → downloadImageToRom (resize), video → downloadVideoToRom. Trả về list với localPath relative.
  Future<List<MediaItem>> downloadAllToRom(List<MediaItem> items) async {
    final result = <MediaItem>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.type != MediaType.image && item.type != MediaType.video) {
        result.add(item);
        continue;
      }
      final url = item.url;
      if (url.isEmpty || url.startsWith('asset:')) {
        result.add(item);
        continue;
      }
      final id = item.id.isNotEmpty ? item.id : '${item.type.name}_$i';
      if (item.type == MediaType.image) {
        final ext = _extensionFromUrl(url);
        final path = await downloadImageToRom(url, id, ext);
        result.add(path != null ? item.copyWith(localPath: path) : item);
      } else {
        final path = await downloadVideoToRom(url, id);
        result.add(path != null ? item.copyWith(localPath: path) : item);
      }
    }
    return result;
  }

  /// LRU: chỉ xóa trong cache/ và file trong images/|videos/ không phải asset cố định (cat_playing, emlakothe, catoon1).
  Future<void> _enforceCacheQuota() async {
    try {
      final base = await rootPath;
      final files = <_FileEntry>[];
      int totalBytes = 0;

      Future<void> scanDir(String subdir) async {
        final dir = Directory('$base/$subdir');
        if (!await dir.exists()) return;
        await for (final entity in dir.list()) {
          if (entity is File) {
            final stat = await entity.stat();
            totalBytes += stat.size;
            files.add(_FileEntry(file: entity, modified: stat.modified, size: stat.size));
          }
        }
      }

      await scanDir(_imagesDir);
      await scanDir(_videosDir);
      await scanDir(_cacheDir);

      if (totalBytes <= _maxCacheBytes) return;

      files.sort((a, b) => a.modified.compareTo(b.modified));
      for (final entry in files) {
        final name = entry.file.path.split('/').last;
        final isFixed = name == 'cat_playing.mp4' ||
            name == 'emlakothe.mp3' ||
            name.contains('catoon1') ||
            name.contains('Cat_playing');
        if (isFixed) continue;
        await entry.file.delete().catchError((_) => entry.file);
        totalBytes -= entry.size;
        if (totalBytes <= _maxCacheBytes) break;
      }
    } catch (e) {
      debugPrint('RomMediaStorage _enforceCacheQuota error: $e');
    }
  }

  String _extensionFromUrl(String url) {
    final u = url.split('?').first.toLowerCase();
    if (u.endsWith('.mp4')) return '.mp4';
    if (u.endsWith('.webm')) return '.webm';
    if (u.endsWith('.webp')) return '.webp';
    if (u.endsWith('.png')) return '.png';
    if (u.endsWith('.jpg') || u.endsWith('.jpeg')) return '.jpg';
    return '.jpg';
  }
}
