import 'package:flutter/foundation.dart';
import '../../models/filter_criteria.dart';
import '../../services/filter/filter.dart';

/// 可筛选的 Provider 基类
/// 
/// 提供通用的筛选功能，子类只需实现具体的业务逻辑
/// 采用模板方法模式，定义筛选的骨架流程
abstract class FilterableProvider<T> extends ChangeNotifier {
  /// 原始数据列表（未筛选）
  List<T> _rawItems = [];

  /// 筛选条件
  FilterCriteria _criteria = const FilterCriteria.empty();

  /// 筛选引擎（延迟初始化）
  late final FilterEngine<T> _filterEngine;

  /// 是否已初始化筛选引擎
  bool _isEngineInitialized = false;

  FilterableProvider() {
    _initializeFilterEngine();
  }

  /// 初始化筛选引擎
  void _initializeFilterEngine() {
    if (!_isEngineInitialized) {
      _filterEngine = createFilterEngine();
      _isEngineInitialized = true;
    }
  }

  /// 创建筛选引擎（由子类实现）
  /// 
  /// 子类需要返回配置了相应筛选策略的 FilterEngine
  @protected
  FilterEngine<T> createFilterEngine();

  /// 获取原始数据列表（未筛选）
  @protected
  List<T> get rawItems => _rawItems;

  /// 设置原始数据列表
  @protected
  set rawItems(List<T> items) {
    _rawItems = items;
    notifyListeners();
  }

  /// 获取筛选后的数据列表（公开给UI使用）
  List<T> get items => _filterEngine.filter(_rawItems, _criteria);

  /// 获取当前筛选条件
  FilterCriteria get criteria => _criteria;

  /// 判断是否有激活的筛选条件
  bool get hasActiveFilters => _criteria.isNotEmpty;

  /// 获取激活的筛选条件数量
  int get activeFilterCount => _criteria.activeFilterCount;

  /// 更新筛选条件
  /// 
  /// [criteria] 新的筛选条件
  void updateFilter(FilterCriteria criteria) {
    if (_criteria == criteria) return;

    _criteria = criteria;
    notifyListeners();
  }

  /// 部分更新筛选条件
  /// 
  /// 使用 copyWith 模式更新特定字段
  void updateFilterPartial({
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
    _criteria = _criteria.copyWith(
      keyword: keyword,
      upName: upName,
      minViewCount: minViewCount,
      maxViewCount: maxViewCount,
      minDanmakuCount: minDanmakuCount,
      maxDanmakuCount: maxDanmakuCount,
      clearKeyword: clearKeyword,
      clearUpName: clearUpName,
      clearMinViewCount: clearMinViewCount,
      clearMaxViewCount: clearMaxViewCount,
      clearMinDanmakuCount: clearMinDanmakuCount,
      clearMaxDanmakuCount: clearMaxDanmakuCount,
    );
    notifyListeners();
  }

  /// 清除所有筛选条件
  void clearFilters() {
    if (_criteria.isEmpty) return;

    _criteria = const FilterCriteria.empty();
    notifyListeners();
  }

  /// 设置关键词筛选
  /// 
  /// [keyword] 关键词，null或空字符串表示清除
  @Deprecated('Use updateFilterPartial instead')
  void setKeywordFilter(String? keyword) {
    updateFilterPartial(
      keyword: keyword,
      clearKeyword: keyword == null || keyword.isEmpty,
    );
  }

  /// 设置UP主筛选
  /// 
  /// [upName] UP主名称，null或空字符串表示清除
  @Deprecated('Use updateFilterPartial instead')
  void setUpNameFilter(String? upName) {
    updateFilterPartial(
      upName: upName,
      clearUpName: upName == null || upName.isEmpty,
    );
  }

  /// 应用多个筛选条件（保持向后兼容）
  /// 
  /// [keyword] 关键词
  /// [upName] UP主名称
  @Deprecated('Use updateFilter with FilterCriteria instead')
  void applyFilters({String? keyword, String? upName}) {
    _criteria = FilterCriteria(
      keyword: keyword?.trim(),
      upName: upName?.trim(),
    );
    notifyListeners();
  }

  /// 获取筛选结果统计信息
  FilterStatistics getFilterStatistics() {
    return FilterStatistics(
      totalCount: _rawItems.length,
      filteredCount: items.length,
      activeFilterCount: activeFilterCount,
      criteria: _criteria,
    );
  }
}

/// 筛选统计信息
class FilterStatistics {
  /// 总数据量
  final int totalCount;

  /// 筛选后的数据量
  final int filteredCount;

  /// 激活的筛选条件数量
  final int activeFilterCount;

  /// 筛选条件
  final FilterCriteria criteria;

  const FilterStatistics({
    required this.totalCount,
    required this.filteredCount,
    required this.activeFilterCount,
    required this.criteria,
  });

  /// 是否有数据被筛选掉
  bool get hasFilteredOut => filteredCount < totalCount;

  /// 筛选掉的数据量
  int get filteredOutCount => totalCount - filteredCount;

  /// 筛选通过率
  double get filterPassRate {
    if (totalCount == 0) return 0.0;
    return filteredCount / totalCount;
  }

  @override
  String toString() {
    return 'FilterStatistics(total: $totalCount, filtered: $filteredCount, '
        'activeFilters: $activeFilterCount)';
  }
}
