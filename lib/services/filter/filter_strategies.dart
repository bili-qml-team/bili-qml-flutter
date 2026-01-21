import '../../models/filter_criteria.dart';
import 'filter_strategy.dart';

/// 标题筛选策略
/// 
/// 根据关键词筛选标题
/// 支持不区分大小写的模糊匹配
class TitleFilterStrategy<T> extends BaseFilterStrategy<T> {
  /// 提取标题的函数
  final String? Function(T item) titleExtractor;

  const TitleFilterStrategy(this.titleExtractor);

  @override
  String get displayName => '标题筛选';

  @override
  bool isActive(FilterCriteria criteria) {
    return criteria.keyword != null && criteria.keyword!.isNotEmpty;
  }

  @override
  bool matchesWhenActive(T item, FilterCriteria criteria) {
    final title = titleExtractor(item);
    if (title == null || title.isEmpty) return false;

    final keyword = criteria.keyword!;
    final lowerTitle = title.toLowerCase();
    final lowerKeyword = keyword.toLowerCase();

    return lowerTitle.contains(lowerKeyword);
  }
}

/// UP主筛选策略
/// 
/// 根据UP主名称筛选
/// 支持不区分大小写的模糊匹配
class UpNameFilterStrategy<T> extends BaseFilterStrategy<T> {
  /// 提取UP主名称的函数
  final String? Function(T item) upNameExtractor;

  const UpNameFilterStrategy(this.upNameExtractor);

  @override
  String get displayName => 'UP主筛选';

  @override
  bool isActive(FilterCriteria criteria) {
    return criteria.upName != null && criteria.upName!.isNotEmpty;
  }

  @override
  bool matchesWhenActive(T item, FilterCriteria criteria) {
    final upName = upNameExtractor(item);
    if (upName == null || upName.isEmpty) return false;

    final filterUpName = criteria.upName!;
    final lowerUpName = upName.toLowerCase();
    final lowerFilterUpName = filterUpName.toLowerCase();

    return lowerUpName.contains(lowerFilterUpName);
  }
}

/// 播放量筛选策略
/// 
/// 根据播放量范围筛选
/// 支持最小值、最大值或范围筛选
class ViewCountFilterStrategy<T> extends BaseFilterStrategy<T> {
  /// 提取播放量的函数
  final int? Function(T item) viewCountExtractor;

  const ViewCountFilterStrategy(this.viewCountExtractor);

  @override
  String get displayName => '播放量筛选';

  @override
  bool isActive(FilterCriteria criteria) {
    return criteria.minViewCount != null || criteria.maxViewCount != null;
  }

  @override
  bool matchesWhenActive(T item, FilterCriteria criteria) {
    final viewCount = viewCountExtractor(item);
    if (viewCount == null) return false;

    // 检查最小值
    if (criteria.minViewCount != null && viewCount < criteria.minViewCount!) {
      return false;
    }

    // 检查最大值
    if (criteria.maxViewCount != null && viewCount > criteria.maxViewCount!) {
      return false;
    }

    return true;
  }
}

/// 弹幕数筛选策略
/// 
/// 根据弹幕数范围筛选
/// 支持最小值、最大值或范围筛选
class DanmakuCountFilterStrategy<T> extends BaseFilterStrategy<T> {
  /// 提取弹幕数的函数
  final int? Function(T item) danmakuCountExtractor;

  const DanmakuCountFilterStrategy(this.danmakuCountExtractor);

  @override
  String get displayName => '弹幕数筛选';

  @override
  bool isActive(FilterCriteria criteria) {
    return criteria.minDanmakuCount != null ||
        criteria.maxDanmakuCount != null;
  }

  @override
  bool matchesWhenActive(T item, FilterCriteria criteria) {
    final danmakuCount = danmakuCountExtractor(item);
    if (danmakuCount == null) return false;

    // 检查最小值
    if (criteria.minDanmakuCount != null &&
        danmakuCount < criteria.minDanmakuCount!) {
      return false;
    }

    // 检查最大值
    if (criteria.maxDanmakuCount != null &&
        danmakuCount > criteria.maxDanmakuCount!) {
      return false;
    }

    return true;
  }
}
