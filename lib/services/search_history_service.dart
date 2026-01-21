import 'package:shared_preferences/shared_preferences.dart';

/// 搜索历史服务
class SearchHistoryService {
  static const String _storageKey = 'searchHistory';
  static const int _maxHistoryCount = 10;

  final SharedPreferences _prefs;

  SearchHistoryService(this._prefs);

  /// 获取搜索历史列表
  List<String> getHistory() {
    return _prefs.getStringList(_storageKey) ?? [];
  }

  /// 添加搜索记录
  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    final history = getHistory();

    // 如果已存在，先移除（避免重复）
    history.remove(query);

    // 添加到开头
    history.insert(0, query);

    // 限制数量
    if (history.length > _maxHistoryCount) {
      history.removeRange(_maxHistoryCount, history.length);
    }

    await _prefs.setStringList(_storageKey, history);
  }

  /// 删除单条记录
  Future<void> removeSearch(String query) async {
    final history = getHistory();
    history.remove(query);
    await _prefs.setStringList(_storageKey, history);
  }

  /// 清空所有历史
  Future<void> clearHistory() async {
    await _prefs.remove(_storageKey);
  }
}
