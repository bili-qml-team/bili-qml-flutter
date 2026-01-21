import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'base/filterable_provider.dart';

/// 浏览历史管理 Provider
class HistoryProvider extends FilterableProvider<HistoryItem> {
  final HistoryService _historyService;

  bool _isLoading = false;

  HistoryProvider(this._historyService);

  /// 历史记录列表（筛选后的）
  List<HistoryItem> get history => items; // 使用基类的 items getter

  /// 所有历史记录（未筛选）
  List<HistoryItem> get allHistory => rawItems;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 历史记录数量（筛选后的）
  int get count => items.length;

  /// 全部历史记录数量（未筛选）
  int get totalCount => rawItems.length;

  @override
  FilterEngine<HistoryItem> createFilterEngine() {
    return FilterEngine<HistoryItem>([
      // 标题筛选策略
      TitleFilterStrategy<HistoryItem>((item) => item.title),
      // UP主筛选策略
      UpNameFilterStrategy<HistoryItem>((item) => item.ownerName),
    ]);
  }

  /// 初始化：加载历史记录
  Future<void> init() async {
    await loadHistory();
  }

  /// 加载历史记录
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      rawItems = await _historyService.getAll();
    } catch (e) {
      debugPrint('加载历史记录失败: $e');
      rawItems = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 添加历史记录
  Future<bool> addHistory(
    String bvid, {
    String? title,
    String? picUrl,
    String? ownerName,
  }) async {
    try {
      final item = HistoryItem.fromLeaderboardItem(
        bvid,
        title: title,
        picUrl: picUrl,
        ownerName: ownerName,
      );

      final success = await _historyService.add(item);
      if (success) {
        await loadHistory(); // 重新加载以更新列表
      }
      return success;
    } catch (e) {
      debugPrint('添加历史记录失败: $e');
      return false;
    }
  }

  /// 移除历史记录
  Future<bool> removeHistory(String bvid) async {
    try {
      final success = await _historyService.remove(bvid);
      if (success) {
        await loadHistory(); // 重新加载以更新列表
      }
      return success;
    } catch (e) {
      debugPrint('移除历史记录失败: $e');
      return false;
    }
  }

  /// 清空所有历史记录
  Future<bool> clearAll() async {
    try {
      final success = await _historyService.clear();
      if (success) {
        rawItems = [];
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('清空历史记录失败: $e');
      return false;
    }
  }

  /// 按日期分组历史记录（使用筛选后的数据）
  Map<String, List<HistoryItem>> getGroupedByDate() {
    final Map<String, List<HistoryItem>> grouped = {};

    for (final item in items) {
      // 使用筛选后的 items
      final dateKey = _getDateKey(item.viewedAt);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(item);
    }

    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final itemDate = DateTime(date.year, date.month, date.day);

    if (itemDate == today) {
      return '今天';
    } else if (itemDate == yesterday) {
      return '昨天';
    } else if (now.difference(itemDate).inDays < 7) {
      return '本周';
    } else if (date.year == now.year && date.month == now.month) {
      return '本月';
    } else {
      return '${date.year}年${date.month}月';
    }
  }
}
