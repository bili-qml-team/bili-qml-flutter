import '../../models/filter_criteria.dart';

/// 筛选策略接口
/// 
/// 采用策略模式，每个策略负责一种筛选逻辑
/// 泛型 T 表示要筛选的数据类型（LeaderboardItem、FavoriteItem等）
abstract class FilterStrategy<T> {
  /// 判断某个数据项是否符合筛选条件
  /// 
  /// [item] 要检查的数据项
  /// [criteria] 筛选条件
  /// 返回 true 表示通过筛选，false 表示不通过
  bool matches(T item, FilterCriteria criteria);

  /// 获取策略的显示名称（用于调试和日志）
  String get displayName;

  /// 判断该策略是否激活（是否有相关筛选条件）
  bool isActive(FilterCriteria criteria);
}

/// 抽象基类：提供通用的激活判断逻辑
abstract class BaseFilterStrategy<T> implements FilterStrategy<T> {
  const BaseFilterStrategy();

  @override
  bool matches(T item, FilterCriteria criteria) {
    // 如果策略未激活，直接通过
    if (!isActive(criteria)) return true;

    // 委托给子类实现具体的匹配逻辑
    return matchesWhenActive(item, criteria);
  }

  /// 当策略激活时的匹配逻辑（由子类实现）
  bool matchesWhenActive(T item, FilterCriteria criteria);
}
