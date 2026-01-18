import '../../models/filter_criteria.dart';
import 'filter_strategy.dart';

/// 筛选引擎
/// 
/// 负责组合多个筛选策略并执行筛选操作
/// 采用AND逻辑：所有激活的策略都必须通过
class FilterEngine<T> {
  /// 筛选策略列表
  final List<FilterStrategy<T>> strategies;

  const FilterEngine(this.strategies);

  /// 对数据列表应用筛选
  /// 
  /// [items] 原始数据列表
  /// [criteria] 筛选条件
  /// 返回筛选后的数据列表
  List<T> filter(List<T> items, FilterCriteria criteria) {
    // 如果没有激活的筛选条件，直接返回原列表
    if (criteria.isEmpty) {
      return items;
    }

    // 获取激活的策略
    final activeStrategies = strategies.where(
      (strategy) => strategy.isActive(criteria),
    ).toList();

    // 如果没有激活的策略，返回原列表
    if (activeStrategies.isEmpty) {
      return items;
    }

    // 对每个数据项应用所有激活的策略（AND逻辑）
    return items.where((item) {
      return activeStrategies.every(
        (strategy) => strategy.matches(item, criteria),
      );
    }).toList();
  }

  /// 判断某个数据项是否通过筛选
  /// 
  /// [item] 要检查的数据项
  /// [criteria] 筛选条件
  /// 返回 true 表示通过，false 表示不通过
  bool matches(T item, FilterCriteria criteria) {
    if (criteria.isEmpty) return true;

    final activeStrategies = strategies.where(
      (strategy) => strategy.isActive(criteria),
    ).toList();

    if (activeStrategies.isEmpty) return true;

    return activeStrategies.every(
      (strategy) => strategy.matches(item, criteria),
    );
  }

  /// 获取激活的策略数量
  int getActiveStrategyCount(FilterCriteria criteria) {
    return strategies.where(
      (strategy) => strategy.isActive(criteria),
    ).length;
  }

  /// 获取激活的策略列表
  List<FilterStrategy<T>> getActiveStrategies(FilterCriteria criteria) {
    return strategies.where(
      (strategy) => strategy.isActive(criteria),
    ).toList();
  }
}
