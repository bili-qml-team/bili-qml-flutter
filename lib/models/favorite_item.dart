/// 收藏视频数据模型
class FavoriteItem {
  /// BV号
  final String bvid;

  /// 视频标题
  final String? title;

  /// 封面图片URL
  final String? picUrl;

  /// UP主名称
  final String? ownerName;

  /// 收藏时间戳
  final DateTime savedAt;

  /// 可选备注
  final String? note;

  const FavoriteItem({
    required this.bvid,
    this.title,
    this.picUrl,
    this.ownerName,
    required this.savedAt,
    this.note,
  });

  /// 从 JSON 反序列化
  factory FavoriteItem.fromJson(Map<String, dynamic> json) {
    return FavoriteItem(
      bvid: json['bvid'] as String,
      title: json['title'] as String?,
      picUrl: json['picUrl'] as String?,
      ownerName: json['ownerName'] as String?,
      savedAt: DateTime.parse(json['savedAt'] as String),
      note: json['note'] as String?,
    );
  }

  /// 序列化为 JSON
  Map<String, dynamic> toJson() {
    return {
      'bvid': bvid,
      'title': title,
      'picUrl': picUrl,
      'ownerName': ownerName,
      'savedAt': savedAt.toIso8601String(),
      'note': note,
    };
  }

  /// 从 LeaderboardItem 创建收藏项
  factory FavoriteItem.fromLeaderboardItem(
    String bvid, {
    String? title,
    String? picUrl,
    String? ownerName,
    String? note,
  }) {
    return FavoriteItem(
      bvid: bvid,
      title: title,
      picUrl: picUrl,
      ownerName: ownerName,
      savedAt: DateTime.now(),
      note: note,
    );
  }

  /// 复制并修改备注
  FavoriteItem copyWith({
    String? bvid,
    String? title,
    String? picUrl,
    String? ownerName,
    DateTime? savedAt,
    String? note,
  }) {
    return FavoriteItem(
      bvid: bvid ?? this.bvid,
      title: title ?? this.title,
      picUrl: picUrl ?? this.picUrl,
      ownerName: ownerName ?? this.ownerName,
      savedAt: savedAt ?? this.savedAt,
      note: note ?? this.note,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FavoriteItem && other.bvid == bvid;
  }

  @override
  int get hashCode => bvid.hashCode;
}
