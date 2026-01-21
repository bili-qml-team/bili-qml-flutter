import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'image_url_service.dart';
import 'storage_service.dart';

/// 收藏服务类
class FavoritesService {
  static const String _storageKey = 'favorites';
  final StorageService _storageService;

  FavoritesService(this._storageService);

  SharedPreferences get _prefs => _storageService.prefs;

  /// 获取所有收藏
  Future<List<FavoriteItem>> getAll() async {
    try {
      final jsonString = _prefs.getString(_storageKey);
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = json.decode(jsonString) as List;
      final favoriteItems = jsonList
          .map((item) => FavoriteItem.fromJson(item as Map<String, dynamic>))
          .toList();
      final sanitizedItems = _sanitizeItems(favoriteItems);
      if (!_listEquals(favoriteItems, sanitizedItems)) {
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

  /// 添加收藏
  Future<bool> add(FavoriteItem item) async {
    try {
      final favorites = await getAll();
      final sanitizedItem = _sanitizeItem(item);

      // 检查是否已存在
      if (favorites.any((fav) => fav.bvid == sanitizedItem.bvid)) {
        return false; // 已存在，不重复添加
      }

      // 添加到列表开头（最新的在前面）
      favorites.insert(0, sanitizedItem);

      // 保存
      final jsonString = json.encode(
        favorites.map((fav) => fav.toJson()).toList(),
      );
      await _prefs.setString(_storageKey, jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 移除收藏
  Future<bool> remove(String bvid) async {
    try {
      final favorites = await getAll();
      final originalLength = favorites.length;

      // 移除指定的收藏
      favorites.removeWhere((fav) => fav.bvid == bvid);

      // 如果没有变化，说明没找到
      if (favorites.length == originalLength) {
        return false;
      }

      // 保存
      final jsonString = json.encode(
        favorites.map((fav) => fav.toJson()).toList(),
      );
      await _prefs.setString(_storageKey, jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 检查是否已收藏
  Future<bool> isFavorited(String bvid) async {
    try {
      final favorites = await getAll();
      return favorites.any((fav) => fav.bvid == bvid);
    } catch (e) {
      return false;
    }
  }

  /// 更新收藏备注
  Future<bool> updateNote(String bvid, String? note) async {
    try {
      final favorites = await getAll();
      final index = favorites.indexWhere((fav) => fav.bvid == bvid);

      if (index == -1) {
        return false; // 未找到
      }

      // 更新备注
      favorites[index] = favorites[index].copyWith(note: note);

      // 保存
      final jsonString = json.encode(
        favorites.map((fav) => fav.toJson()).toList(),
      );
      await _prefs.setString(_storageKey, jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 清空所有收藏
  Future<bool> clear() async {
    try {
      await _prefs.remove(_storageKey);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取收藏数量
  Future<int> getCount() async {
    final favorites = await getAll();
    return favorites.length;
  }

  FavoriteItem _sanitizeItem(FavoriteItem item) {
    final sanitizedUrl = sanitizeCoverUrl(item.picUrl);
    if (sanitizedUrl == item.picUrl) {
      return item;
    }
    return item.copyWith(picUrl: sanitizedUrl);
  }

  List<FavoriteItem> _sanitizeItems(List<FavoriteItem> items) {
    return items.map(_sanitizeItem).toList();
  }

  bool _listEquals(List<FavoriteItem> a, List<FavoriteItem> b) {
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
