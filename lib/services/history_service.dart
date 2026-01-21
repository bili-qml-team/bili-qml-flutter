import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
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
      return jsonList
          .map((item) => HistoryItem.fromJson(item as Map<String, dynamic>))
          .toList();
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

      // 移除相同BV号的旧记录（如果存在）
      history.removeWhere((h) => h.bvid == item.bvid);

      // 添加到列表开头（最新的在前面）
      history.insert(0, item);

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
}
