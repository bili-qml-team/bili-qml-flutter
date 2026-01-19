/// 排行榜条目模型
class LeaderboardItem {
  final String bvid;
  final int count;
  String? title;
  String? picUrl;
  String? ownerName;
  int? viewCount;
  int? danmakuCount;

  LeaderboardItem({
    required this.bvid,
    required this.count,
    this.title,
    this.picUrl,
    this.ownerName,
    this.viewCount,
    this.danmakuCount,
  });

  factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
    return LeaderboardItem(
      bvid: json['bvid'] as String,
      count: json['count'] as int,
      title: json['title'] as String?,
      picUrl: json['picUrl'] as String?,
      ownerName: json['ownerName'] as String?,
      viewCount: json['viewCount'] as int?,
      danmakuCount: json['danmakuCount'] as int?,
    );
  }

  /// 序列化为 JSON（用于缓存）
  Map<String, dynamic> toJson() {
    return {
      'bvid': bvid,
      'count': count,
      'title': title,
      'picUrl': picUrl,
      'ownerName': ownerName,
      'viewCount': viewCount,
      'danmakuCount': danmakuCount,
    };
  }

  /// 从排行榜 API 和 B站视频信息合并创建
  LeaderboardItem copyWithVideoInfo({
    String? title,
    String? picUrl,
    String? ownerName,
    int? viewCount,
    int? danmakuCount,
  }) {
    return LeaderboardItem(
      bvid: bvid,
      count: count,
      title: title ?? this.title,
      picUrl: picUrl ?? this.picUrl,
      ownerName: ownerName ?? this.ownerName,
      viewCount: viewCount ?? this.viewCount,
      danmakuCount: danmakuCount ?? this.danmakuCount,
    );
  }
}
