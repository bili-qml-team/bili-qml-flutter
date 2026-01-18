import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'base/filterable_provider.dart';

/// 收藏管理 Provider
class FavoritesProvider extends FilterableProvider<FavoriteItem> {
  final FavoritesService _favoritesService;

  bool _isLoading = false;

  FavoritesProvider(this._favoritesService);

  /// 收藏列表（筛选后的）
  List<FavoriteItem> get favorites => items; // 使用基类的 items getter

  /// 所有收藏（未筛选）
  List<FavoriteItem> get allFavorites => rawItems;

  /// 是否正在加载
  bool get isLoading => _isLoading;

  /// 收藏数量（筛选后的）
  int get count => items.length;

  /// 全部收藏数量（未筛选）
  int get totalCount => rawItems.length;

  @override
  FilterEngine<FavoriteItem> createFilterEngine() {
    return FilterEngine<FavoriteItem>([
      // 标题筛选策略
      TitleFilterStrategy<FavoriteItem>((item) => item.title),
      // UP主筛选策略
      UpNameFilterStrategy<FavoriteItem>((item) => item.ownerName),
    ]);
  }

  /// 初始化：加载收藏列表
  Future<void> init() async {
    await loadFavorites();
  }

  /// 加载收藏列表
  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      rawItems = await _favoritesService.getAll();
    } catch (e) {
      debugPrint('加载收藏列表失败: $e');
      rawItems = [];
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
    return rawItems.any((fav) => fav.bvid == bvid);
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
        rawItems = [];
        notifyListeners();
      }
      return success;
    } catch (e) {
      debugPrint('清空收藏失败: $e');
      return false;
    }
  }

  /// 按日期分组收藏（使用筛选后的数据）
  Map<String, List<FavoriteItem>> getGroupedByDate() {
    final Map<String, List<FavoriteItem>> grouped = {};

    for (final item in items) {
      // 使用筛选后的 items
      final dateKey = _getDateKey(item.savedAt);
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
