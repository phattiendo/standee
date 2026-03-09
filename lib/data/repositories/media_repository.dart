import '../../core/storage/rom_media_storage.dart';
import '../datasources/local_media_datasource.dart';
import '../datasources/remote_media_datasource.dart';
import '../models/media_item_model.dart';

/// Repository: offline-first, tải file từ API xuống ROM rồi mới lưu playlist.
class MediaRepository {
  MediaRepository({
    LocalMediaDataSource? local,
    RemoteMediaDataSource? remote,
    bool saveToRom = true,
  })  : _local = local ?? LocalMediaDataSource(),
        _remote = remote ?? RemoteMediaDataSource(),
        _saveToRom = saveToRom;

  final LocalMediaDataSource _local;
  final RemoteMediaDataSource _remote;
  final bool _saveToRom;

  Future<void> init() async {
    await _local.init();
  }

  /// Load playlist từ cache (đã có localPath nếu đã tải ROM trước đó).
  Future<List<MediaItem>> loadInitial() async {
    return _local.loadCachedMedia();
  }

  /// Game-update style: check version → nếu mới hơn local thì download playlist + media, update Hive. Trả về list mới nếu đã update.
  Future<List<MediaItem>?> checkVersionAndUpdateIfNeeded() async {
    final localVersion = _local.getPlaylistVersion();
    final remoteVersion = await _remote.fetchVersion();
    if (remoteVersion <= 0 || remoteVersion <= localVersion) return null;
    final updated = await refreshFromRemote();
    if (updated.isNotEmpty) {
      await _local.savePlaylistVersion(remoteVersion);
      return updated;
    }
    return null;
  }

  /// Gọi API lấy danh sách → tải từng file (ảnh/video) xuống ROM → lưu playlist (có localPath).
  Future<List<MediaItem>> refreshFromRemote() async {
    final remoteItems = await _remote.fetchMediaList();
    if (remoteItems.isEmpty) return remoteItems;

    List<MediaItem> toSave = remoteItems;
    if (_saveToRom) {
      toSave = await RomMediaStorage.I.downloadAllToRom(remoteItems);
    }

    await _local.saveMedia(toSave);
    return toSave;
  }
}

