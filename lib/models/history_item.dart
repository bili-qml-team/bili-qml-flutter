/// 浏览历史数据模型
class HistoryItem {
  /// BV号
  final String bvid;

  /// 视频标题
  final String? title;

  /// 封面图片URL
  final String? picUrl;

  /// UP主名称
  final String? ownerName;

  /// 浏览时间戳
  final DateTime viewedAt;

  const HistoryItem({
    required this.bvid,
    this.title,
    this.picUrl,
    this.ownerName,
    required this.viewedAt,
  });

  /// 从 JSON 反序列化
  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      bvid: json['bvid'] as String,
      title: json['title'] as String?,
      picUrl: json['picUrl'] as String?,
      ownerName: json['ownerName'] as String?,
      viewedAt: DateTime.parse(json['viewedAt'] as String),
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'bvid': bvid,
      'title': title,
      'picUrl': picUrl,
      'ownerName': ownerName,
      'viewedAt': viewedAt.toIso8601String(),
    };
  }

  /// 从 LeaderboardItem 创建历史项
  factory HistoryItem.fromLeaderboardItem(
    String bvid, {
    String? title,
    String? picUrl,
    String? ownerName,
  }) {
    return HistoryItem(
      bvid: bvid,
      title: title,
      picUrl: picUrl,
      ownerName: ownerName,
      viewedAt: DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HistoryItem && other.bvid == bvid;
  }

  @override
  int get hashCode => bvid.hashCode;
}
