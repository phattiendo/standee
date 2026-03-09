enum MediaType { image, video, sdp }

class MediaItem {
  /// Id từ API (để so sánh version, redownload khi server đổi media).
  final String id;

  final String url;
  final MediaType type;

  /// Thời gian hiển thị (giây). Nếu API không có thì fallback = 10.
  final int durationSeconds;

  /// Background asset cho SDP (nếu có)
  final String? sdpBackgroundAsset;

  /// Đường dẫn file trên ROM (relative: images/xxx.jpg, videos/xxx.mp4). Dùng để phát offline.
  final String? localPath;

  const MediaItem({
    this.id = '',
    required this.url,
    required this.type,
    required this.durationSeconds,
    this.sdpBackgroundAsset,
    this.localPath,
  });

  /// URL/path dùng để phát: ưu tiên file local (ROM). Nếu localPath relative (images/xx) cần ghép với root.
  String get playbackUrl => (localPath != null && localPath!.isNotEmpty) ? localPath! : url;

  factory MediaItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final url = json['url'] as String? ?? '';
    final typeStr = (json['type'] as String? ?? 'image').toLowerCase();
    final duration =
        json['durationSeconds'] as int? ?? json['duration'] as int? ?? 10;

    MediaType type;
    if (typeStr == 'video') {
      type = MediaType.video;
    } else if (typeStr == 'sdp') {
      type = MediaType.sdp;
    } else {
      type = MediaType.image;
    }

    return MediaItem(
      id: id,
      url: url,
      type: type,
      durationSeconds: duration > 0 ? duration : 10,
      sdpBackgroundAsset: json['sdpBackgroundAsset'] as String?,
      localPath: json['localPath'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'url': url,
        'type': type.name,
        'durationSeconds': durationSeconds,
        if (sdpBackgroundAsset != null)
          'sdpBackgroundAsset': sdpBackgroundAsset,
        if (localPath != null) 'localPath': localPath,
      };

  MediaItem copyWith({String? localPath}) {
    return MediaItem(
      id: id,
      url: url,
      type: type,
      durationSeconds: durationSeconds,
      sdpBackgroundAsset: sdpBackgroundAsset,
      localPath: localPath ?? this.localPath,
    );
  }

  /// Factory để tạo SDP item
  factory MediaItem.sdp({
    String id = 'sdp',
    int durationSeconds = 15,
    String? backgroundAsset,
    String? posterUrl,
  }) {
    return MediaItem(
      id: id,
      url: posterUrl ?? '',
      type: MediaType.sdp,
      durationSeconds: durationSeconds,
      sdpBackgroundAsset: backgroundAsset,
    );
  }

  /// Factory để tạo Video item
  factory MediaItem.video({
    String id = '',
    required String url,
    int durationSeconds = 30,
    String? localPath,
  }) {
    return MediaItem(
      id: id,
      url: url,
      type: MediaType.video,
      durationSeconds: durationSeconds,
      localPath: localPath,
    );
  }

  /// Factory để tạo Image item
  factory MediaItem.image({
    String id = '',
    required String url,
    int durationSeconds = 10,
    String? localPath,
  }) {
    return MediaItem(
      id: id,
      url: url,
      type: MediaType.image,
      durationSeconds: durationSeconds,
      localPath: localPath,
    );
  }
}

