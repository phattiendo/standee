enum MediaType { image, video, sdp }

class MediaItem {
  final String url;
  final MediaType type;

  /// Thời gian hiển thị (giây). Nếu API không có thì fallback = 10.
  final int durationSeconds;

  /// Background asset cho SDP (nếu có)
  final String? sdpBackgroundAsset;

  const MediaItem({
    required this.url,
    required this.type,
    required this.durationSeconds,
    this.sdpBackgroundAsset,
  });

  factory MediaItem.fromJson(Map<String, dynamic> json) {
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
      url: url,
      type: type,
      durationSeconds: duration > 0 ? duration : 10,
      sdpBackgroundAsset: json['sdpBackgroundAsset'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'url': url,
        'type': type.name,
        'durationSeconds': durationSeconds,
        if (sdpBackgroundAsset != null)
          'sdpBackgroundAsset': sdpBackgroundAsset,
      };

  /// Factory để tạo SDP item
  factory MediaItem.sdp({
    int durationSeconds = 15,
    String? backgroundAsset,
    String? posterUrl,
  }) {
    return MediaItem(
      url: posterUrl ?? '',
      type: MediaType.sdp,
      durationSeconds: durationSeconds,
      sdpBackgroundAsset: backgroundAsset,
    );
  }

  /// Factory để tạo Video item
  factory MediaItem.video({
    required String url,
    int durationSeconds = 30,
  }) {
    return MediaItem(
      url: url,
      type: MediaType.video,
      durationSeconds: durationSeconds,
    );
  }

  /// Factory để tạo Image item
  factory MediaItem.image({
    required String url,
    int durationSeconds = 10,
  }) {
    return MediaItem(
      url: url,
      type: MediaType.image,
      durationSeconds: durationSeconds,
    );
  }
}

