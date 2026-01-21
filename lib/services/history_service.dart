import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'image_url_service.dart';
import 'storage_service.dart';

/// 浏览历史服务类
class HistoryService {
  static const String _storageKey = 'browseHistory';
  static const int _maxHistoryCount = 100; // 最多保留100条历史记录

  final StorageService _storageService;

  HistoryService(this._storageService);

  SharedPreferences get _prefs => _storageService.prefs;

  /// 获取所有历史记录
  Future<List<HistoryItem>> getAll() async {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString) as List;
      final historyItems = jsonList
          .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
      final sanitizedItems = _sanitizeItems(historyItems);
      if (!_listEquals(historyItems, sanitizedItems)) {
        final jsonString = json.encode(
          sanitizedItems.map((item) => item.toJson()).toList(),
        );
        await _prefs.setString(_storageKey, jsonString);
      }
      return sanitizedItems;
    } catch (e) {
      // 如果解析失败，返回空列表并清除损坏的数据
      await _prefs.remove(_storageKey);
      return [];
    }
  }

  /// 添加历史记录
  /// 如果已存在相同BV号，则更新时间并移到最前面
  Future<bool> add(HistoryItem item) async {
    try {
      var history = await getAll();
      final sanitizedItem = _sanitizeItem(item);

      // 移除相同BV号的旧记录（如果存在）
      history.removeWhere((h) => h.bvid == sanitizedItem.bvid);

      // 添加到列表开头（最新的在前面）
      history.insert(0, sanitizedItem);

      // 限制历史记录数量
      if (history.length > _maxHistoryCount) {
        history = history.sublist(0, _maxHistoryCount);
      }

      // 保存
      final jsonString = json.encode(history.map((h) => h.toJson()).toList());
      await _prefs.setString(_storageKey, jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 移除历史记录
  Future<bool> remove(String bvid) async {
    try {
      final history = await getAll();
      final originalLength = history.length;

      // 移除指定的记录
      history.removeWhere((h) => h.bvid == bvid);

      // 如果没有变化，说明没找到
      if (history.length == originalLength) {
        return false;
      }

      // 保存
      final jsonString = json.encode(history.map((h) => h.toJson()).toList());
      await _prefs.setString(_storageKey, jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清空所有历史记录
  Future<bool> clear() async {
    try {
      await _prefs.remove(_storageKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取历史记录数量
  Future<int> getCount() async {
    final history = await getAll();
    return history.length;
  }

  HistoryItem _sanitizeItem(HistoryItem item) {
    final sanitizedUrl = sanitizeCoverUrl(item.picUrl);
    if (sanitizedUrl == item.picUrl) {
      return item;
    }
    return HistoryItem(
      bvid: item.bvid,
      title: item.title,
      picUrl: sanitizedUrl,
      ownerName: item.ownerName,
      viewedAt: item.viewedAt,
    );
  }

  List<HistoryItem> _sanitizeItems(List<HistoryItem> items) {
    return items.map(_sanitizeItem).toList();
  }

  bool _listEquals(List<HistoryItem> a, List<HistoryItem> b) {
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i++) {
      if (a[i].bvid != b[i].bvid || a[i].picUrl != b[i].picUrl) {
        return false;
      }
    }
    return true;
  }
}
