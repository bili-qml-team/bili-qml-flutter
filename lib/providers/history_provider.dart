import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// 浏览历史管理 Provider
class HistoryProvider extends ChangeNotifier {
  final HistoryService _historyService;

  List<HistoryItem> _history = [];
  bool _isLoading = false;

  HistoryProvider(this._historyService);

  /// 历史记录列表
  List<HistoryItem> get history => _history;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 历史记录数量
  int get count => _history.length;

  /// 初始化：加载历史记录
  Future<void> init() async {
    await loadHistory();
  }

  /// 加载历史记录
  Future<void> loadHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      _history = await _historyService.getAll();
    } catch (e) {
      debugPrint('加载历史记录失败: $e');
      _history = [];
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
        _history = [];
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('清空历史记录失败: $e');
      return false;
    }
  }

  /// 按日期分组历史记录
  Map<String, List<HistoryItem>> getGroupedByDate() {
    final Map<String, List<HistoryItem>> grouped = {};

    for (final item in _history) {
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
