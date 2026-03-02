/// Model chứa thông tin Standee từ API /api/standee
class StandeeInfo {
  final String standeeId;
  final String standeeName;
  final String alias;
  final String mainTitle;
  final String subTitle;
  final int displayDuration;
  final String? spaceId;

  const StandeeInfo({
    required this.standeeId,
    required this.standeeName,
    required this.alias,
    required this.mainTitle,
    required this.subTitle,
    required this.displayDuration,
    this.spaceId,
  });

  /// Display name theo format "Block {alias}"
  String get displayName => 'Block $alias';

  factory StandeeInfo.fromJson(Map<String, dynamic> json) {
    return StandeeInfo(
      standeeId: json['standeeId'] as String? ?? '',
      standeeName: json['standeeName'] as String? ?? '',
      alias: json['alias'] as String? ?? '',
      mainTitle: json['mainTitle'] as String? ?? '',
      subTitle: json['subTitle'] as String? ?? '',
      displayDuration: json['displayDuration'] as int? ?? 15,
      spaceId: json['spaceId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'standeeId': standeeId,
        'standeeName': standeeName,
        'alias': alias,
        'mainTitle': mainTitle,
        'subTitle': subTitle,
        'displayDuration': displayDuration,
        'spaceId': spaceId,
      };

  factory StandeeInfo.empty() => const StandeeInfo(
        standeeId: '',
        standeeName: '',
        alias: '',
        mainTitle: '',
        subTitle: '',
        displayDuration: 15,
      );

  bool get isEmpty => standeeId.isEmpty;
}
