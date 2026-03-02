import '../datasources/local_media_datasource.dart';
import '../datasources/remote_media_datasource.dart';
import '../models/media_item_model.dart';

/// Repository: xử lý logic offline-first
class MediaRepository {
  MediaRepository({
    LocalMediaDataSource? local,
    RemoteMediaDataSource? remote,
  })  : _local = local ?? LocalMediaDataSource(),
        _remote = remote ?? RemoteMediaDataSource();

  final LocalMediaDataSource _local;
  final RemoteMediaDataSource _remote;

  Future<void> init() async {
    await _local.init();
  }

  /// Load cache trước, sau đó bắn API ở background
  Future<List<MediaItem>> loadInitial() async {
    return _local.loadCachedMedia();
  }

  Future<List<MediaItem>> refreshFromRemote() async {
    final remoteItems = await _remote.fetchMediaList();
    if (remoteItems.isNotEmpty) {
      await _local.saveMedia(remoteItems);
    }
    return remoteItems;
  }
}

