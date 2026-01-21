/// 筛选条件模型
/// 
/// 封装所有可能的筛选条件，采用不可变设计
class FilterCriteria {
  /// 标题关键词
  final String? keyword;

  /// UP主名称
  final String? upName;

  /// 最小播放量
  final int? minViewCount;

  /// 最大播放量
  final int? maxViewCount;

  /// 最小弹幕数
  final int? minDanmakuCount;

  /// 最大弹幕数
  final int? maxDanmakuCount;

  const FilterCriteria({
    this.keyword,
    this.upName,
    this.minViewCount,
    this.maxViewCount,
    this.minDanmakuCount,
    this.maxDanmakuCount,
  });

  /// 空筛选条件（无任何筛选）
  const FilterCriteria.empty()
      : keyword = null,
        upName = null,
        minViewCount = null,
        maxViewCount = null,
        minDanmakuCount = null,
        maxDanmakuCount = null;

  /// 仅关键词筛选
  const FilterCriteria.keyword(this.keyword)
      : upName = null,
        minViewCount = null,
        maxViewCount = null,
        minDanmakuCount = null,
        maxDanmakuCount = null;

  /// 仅UP主筛选
  const FilterCriteria.upName(this.upName)
      : keyword = null,
        minViewCount = null,
        maxViewCount = null,
        minDanmakuCount = null,
        maxDanmakuCount = null;

  /// 判断是否为空（无任何筛选条件）
  bool get isEmpty {
    return keyword == null &&
        upName == null &&
        minViewCount == null &&
        maxViewCount == null &&
        minDanmakuCount == null &&
        maxDanmakuCount == null;
  }

  /// 判断是否有效（至少有一个筛选条件）
  bool get isNotEmpty => !isEmpty;

  /// 判断是否有文本筛选（关键词或UP主）
  bool get hasTextFilter => keyword != null || upName != null;

  /// 判断是否有数值筛选（播放量或弹幕数）
  bool get hasNumericFilter =>
      minViewCount != null ||
      maxViewCount != null ||
      minDanmakuCount != null ||
      maxDanmakuCount != null;

  /// 获取激活的筛选条件数量
  int get activeFilterCount {
    int count = 0;
    if (keyword != null && keyword!.isNotEmpty) count++;
    if (upName != null && upName!.isNotEmpty) count++;
    if (minViewCount != null) count++;
    if (maxViewCount != null) count++;
    if (minDanmakuCount != null) count++;
    if (maxDanmakuCount != null) count++;
    return count;
  }

  /// 创建副本并更新指定字段（不可变更新）
  FilterCriteria copyWith({
    String? keyword,
    String? upName,
    int? minViewCount,
    int? maxViewCount,
    int? minDanmakuCount,
    int? maxDanmakuCount,
    bool clearKeyword = false,
    bool clearUpName = false,
    bool clearMinViewCount = false,
    bool clearMaxViewCount = false,
    bool clearMinDanmakuCount = false,
    bool clearMaxDanmakuCount = false,
  }) {
    return FilterCriteria(
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      upName: clearUpName ? null : (upName ?? this.upName),
      minViewCount:
          clearMinViewCount ? null : (minViewCount ?? this.minViewCount),
      maxViewCount:
          clearMaxViewCount ? null : (maxViewCount ?? this.maxViewCount),
      minDanmakuCount: clearMinDanmakuCount
          ? null
          : (minDanmakuCount ?? this.minDanmakuCount),
      maxDanmakuCount: clearMaxDanmakuCount
          ? null
          : (maxDanmakuCount ?? this.maxDanmakuCount),
    );
  }

  /// 序列化为JSON（用于保存筛选历史）
  Map<String, dynamic> toJson() {
    return {
      if (keyword != null) 'keyword': keyword,
      if (upName != null) 'upName': upName,
      if (minViewCount != null) 'minViewCount': minViewCount,
      if (maxViewCount != null) 'maxViewCount': maxViewCount,
      if (minDanmakuCount != null) 'minDanmakuCount': minDanmakuCount,
      if (maxDanmakuCount != null) 'maxDanmakuCount': maxDanmakuCount,
    };
  }

  /// 从JSON反序列化
  factory FilterCriteria.fromJson(Map<String, dynamic> json) {
    return FilterCriteria(
      keyword: json['keyword'] as String?,
      upName: json['upName'] as String?,
      minViewCount: json['minViewCount'] as int?,
      maxViewCount: json['maxViewCount'] as int?,
      minDanmakuCount: json['minDanmakuCount'] as int?,
      maxDanmakuCount: json['maxDanmakuCount'] as int?,
    );
  }

  /// 获取筛选条件的可读描述
  String getDescription() {
    final parts = <String>[];

    if (keyword != null && keyword!.isNotEmpty) {
      parts.add('标题包含"$keyword"');
    }

    if (upName != null && upName!.isNotEmpty) {
      parts.add('UP主"$upName"');
    }

    if (minViewCount != null || maxViewCount != null) {
      if (minViewCount != null && maxViewCount != null) {
        parts.add('播放量 $minViewCount-$maxViewCount');
      } else if (minViewCount != null) {
        parts.add('播放量 ≥$minViewCount');
      } else {
        parts.add('播放量 ≤$maxViewCount');
      }
    }

    if (minDanmakuCount != null || maxDanmakuCount != null) {
      if (minDanmakuCount != null && maxDanmakuCount != null) {
        parts.add('弹幕数 $minDanmakuCount-$maxDanmakuCount');
      } else if (minDanmakuCount != null) {
        parts.add('弹幕数 ≥$minDanmakuCount');
      } else {
        parts.add('弹幕数 ≤$maxDanmakuCount');
      }
    }

    return parts.isEmpty ? '无筛选' : parts.join('、');
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is FilterCriteria &&
        other.keyword == keyword &&
        other.upName == upName &&
        other.minViewCount == minViewCount &&
        other.maxViewCount == maxViewCount &&
        other.minDanmakuCount == minDanmakuCount &&
        other.maxDanmakuCount == maxDanmakuCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      keyword,
      upName,
      minViewCount,
      maxViewCount,
      minDanmakuCount,
      maxDanmakuCount,
    );
  }

  @override
  String toString() {
    return 'FilterCriteria(${getDescription()})';
  }
}
