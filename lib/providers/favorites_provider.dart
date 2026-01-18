import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';

/// 收藏管理 Provider
class FavoritesProvider extends ChangeNotifier {
  final FavoritesService _favoritesService;

  List<FavoriteItem> _favorites = [];
  bool _isLoading = false;

  FavoritesProvider(this._favoritesService);

  /// 收藏列表
  List<FavoriteItem> get favorites => _favorites;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 收藏数量
  int get count => _favorites.length;

  /// 初始化：加载收藏列表
  Future<void> init() async {
    await loadFavorites();
  }

  /// 加载收藏列表
  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      _favorites = await _favoritesService.getAll();
    } catch (e) {
      debugPrint('加载收藏列表失败: $e');
      _favorites = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 添加收藏
  Future<bool> addFavorite(
    String bvid, {
    String? title,
    String? picUrl,
    String? ownerName,
    String? note,
  }) async {
    try {
      final item = FavoriteItem.fromLeaderboardItem(
        bvid,
        title: title,
        picUrl: picUrl,
        ownerName: ownerName,
        note: note,
      );

      final success = await _favoritesService.add(item);
      if (success) {
        await loadFavorites(); // 重新加载以更新列表
      }
      return success;
    } catch (e) {
      debugPrint('添加收藏失败: $e');
      return false;
    }
  }

  /// 移除收藏
  Future<bool> removeFavorite(String bvid) async {
    try {
      final success = await _favoritesService.remove(bvid);
      if (success) {
        await loadFavorites(); // 重新加载以更新列表
      }
      return success;
    } catch (e) {
      debugPrint('移除收藏失败: $e');
      return false;
    }
  }

  /// 切换收藏状态
  Future<bool> toggleFavorite(
    String bvid, {
    String? title,
    String? picUrl,
    String? ownerName,
  }) async {
    final isFav = await isFavorited(bvid);
    if (isFav) {
      return await removeFavorite(bvid);
    } else {
      return await addFavorite(
        bvid,
        title: title,
        picUrl: picUrl,
        ownerName: ownerName,
      );
    }
  }

  /// 检查是否已收藏
  Future<bool> isFavorited(String bvid) async {
    return await _favoritesService.isFavorited(bvid);
  }

  /// 同步检查是否已收藏（用于UI显示）
  bool isFavoritedSync(String bvid) {
    return _favorites.any((fav) => fav.bvid == bvid);
  }

  /// 更新收藏备注
  Future<bool> updateNote(String bvid, String? note) async {
    try {
      final success = await _favoritesService.updateNote(bvid, note);
      if (success) {
        await loadFavorites(); // 重新加载以更新列表
      }
      return success;
    } catch (e) {
      debugPrint('更新收藏备注失败: $e');
      return false;
    }
  }

  /// 清空所有收藏
  Future<bool> clearAll() async {
    try {
      final success = await _favoritesService.clear();
      if (success) {
        _favorites = [];
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('清空收藏失败: $e');
      return false;
    }
  }
}
