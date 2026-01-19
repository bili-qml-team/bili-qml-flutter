import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'base/filterable_provider.dart';

/// 排行榜状态管理
class LeaderboardProvider extends FilterableProvider<LeaderboardItem> {
  final ApiService _apiService;
  final SharedPreferences _prefs;

  LeaderboardRange _currentRange = LeaderboardRange.realtime;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  bool _requiresCaptcha = false;

  // 分页相关
  int _currentPage = 1;
  static const int _maxPage = 10; // API 支持的最大页数
  static const int _itemsPerPage = 20; // 每页条目数

  // 无限滚动：存储所有已加载的数据
  final List<LeaderboardItem> _allItems = [];

  LeaderboardProvider(this._apiService, this._prefs);

  // Getters
  LeaderboardRange get currentRange => _currentRange;
  List<LeaderboardItem> get allItems => _allItems; // 所有已加载的数据
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get error => _error;
  bool get requiresCaptcha => _requiresCaptcha;

  // 无限滚动相关 getters
  int get currentPage => _currentPage;
  int get maxPage => _maxPage;
  bool get hasMore => _currentPage < _maxPage;
  bool get canLoadMore => hasMore && !_isLoading && !_isLoadingMore;

  // 向后兼容的 getters（已废弃，使用基类的 criteria）
  @Deprecated('Use criteria.keyword instead')
  String? get searchQuery => criteria.keyword;

  @Deprecated('Use criteria.upName instead')
  String? get upNameFilter => criteria.upName;

  // 保留旧的分页 getter 用于兼容（但实际上不再需要手动翻页）
  bool get canGoPreviousPage => false;
  bool get canGoNextPage => hasMore;

  @override
  List<LeaderboardItem> get rawItems => _allItems;

  @override
  List<LeaderboardItem> get items => filterEngine.filter(_allItems, criteria);

  @override
  set rawItems(List<LeaderboardItem> items) {
    // 在无限滚动模式下不直接设置，使用 _allItems
  }

  @override
  FilterEngine<LeaderboardItem> createFilterEngine() {
    return FilterEngine<LeaderboardItem>([
      // 标题筛选策略
      TitleFilterStrategy<LeaderboardItem>((item) => item.title),
      // UP主筛选策略
      UpNameFilterStrategy<LeaderboardItem>((item) => item.ownerName),
      // 播放量筛选策略
      ViewCountFilterStrategy<LeaderboardItem>((item) => item.viewCount),
      // 弹幕数筛选策略
      DanmakuCountFilterStrategy<LeaderboardItem>((item) => item.danmakuCount),
    ]);
  }

  /// 设置搜索关键词（向后兼容，已废弃）
  @Deprecated('Use updateFilterPartial(keyword: ...) instead')
  void setSearchQuery(String? query) {
    updateFilterPartial(
      keyword: query?.trim(),
      clearKeyword: query == null || query.isEmpty,
    );
  }

  /// 设置 UP主 筛选（向后兼容，已废弃）
  @override
  @Deprecated('Use updateFilterPartial(upName: ...) instead')
  void setUpNameFilter(String? upName) {
    updateFilterPartial(
      upName: upName?.trim(),
      clearUpName: upName == null || upName.isEmpty,
    );
  }

  /// 切换时间范围
  Future<void> setRange(LeaderboardRange range) async {
    if (_currentRange == range && _allItems.isNotEmpty) return;

    _currentRange = range;
    _currentPage = 1;
    _allItems.clear();
    notifyListeners();
    await fetchLeaderboard();
  }

  /// 获取缓存键
  String _getCacheKey(LeaderboardRange range) {
    return '${ApiConfig.storageKeyLeaderboardCache}_${range.value}';
  }

  /// 获取缓存时间键
  String _getCacheTimeKey(LeaderboardRange range) {
    return '${ApiConfig.storageKeyLeaderboardCacheTime}_${range.value}';
  }

  /// 检查缓存是否有效（10分钟内）
  bool _isCacheValid(LeaderboardRange range) {
    final cacheTimeKey = _getCacheTimeKey(range);
    final cacheTime = _prefs.getInt(cacheTimeKey);
    if (cacheTime == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;
    return (now - cacheTime) < ApiConfig.leaderboardCacheDuration;
  }

  /// 从缓存加载数据
  Future<bool> _loadFromCache(LeaderboardRange range) async {
    if (!_isCacheValid(range)) return false;

    final cacheKey = _getCacheKey(range);
    final cachedData = _prefs.getString(cacheKey);
    if (cachedData == null) return false;

    try {
      final List<dynamic> jsonList = json.decode(cachedData);
      final items = jsonList
          .map((e) => LeaderboardItem.fromJson(e as Map<String, dynamic>))
          .toList();

      if (items.isEmpty) return false;

      _allItems.clear();
      _allItems.addAll(items);
      // 根据缓存数据计算当前页码
      _currentPage = (items.length / _itemsPerPage).ceil();
      if (_currentPage < 1) _currentPage = 1;

      debugPrint('Loaded ${items.length} items from cache for ${range.value}');
      return true;
    } catch (e) {
      debugPrint('Failed to load cache: $e');
      return false;
    }
  }

  /// 保存数据到缓存
  Future<void> _saveToCache(LeaderboardRange range) async {
    final cacheKey = _getCacheKey(range);
    final cacheTimeKey = _getCacheTimeKey(range);

    try {
      final jsonList = _allItems.map((e) => e.toJson()).toList();
      await _prefs.setString(cacheKey, json.encode(jsonList));
      await _prefs.setInt(cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
      debugPrint('Saved ${_allItems.length} items to cache for ${range.value}');
    } catch (e) {
      debugPrint('Failed to save cache: $e');
    }
  }

  /// 获取排行榜数据（首次加载或刷新）
  Future<void> fetchLeaderboard({String? altchaSolution}) async {
    _isLoading = true;
    _error = null;
    _requiresCaptcha = false;
    notifyListeners();

    // 首次加载时尝试从缓存读取
    if (_allItems.isEmpty && altchaSolution == null) {
      final loadedFromCache = await _loadFromCache(_currentRange);
      if (loadedFromCache) {
        _isLoading = false;
        notifyListeners();
        return;
      }
    }

    // 重置状态
    _currentPage = 1;
    _allItems.clear();

    try {
      debugPrint('Fetching leaderboard: range=$_currentRange, page=$_currentPage');
      final response = await _apiService.getLeaderboard(
        _currentRange,
        altcha: altchaSolution,
        page: _currentPage,
      );

      if (response.requiresCaptcha) {
        _requiresCaptcha = true;
        _error = '需要人机验证';
      } else if (response.success) {
        debugPrint('Received ${response.list.length} items for page $_currentPage');
        if (response.list.isNotEmpty) {
          debugPrint('First 3 BVIDs: ${response.list.take(3).map((e) => e.bvid).join(", ")}');
        }
        _allItems.addAll(response.list);
        // 异步加载视频详情
        _loadVideoDetails(0, _allItems.length);
        // 保存到缓存
        _saveToCache(_currentRange);
      } else {
        _error = response.error ?? '获取排行榜失败';
      }
    } catch (e) {
      _error = '网络错误: ${e.toString()}';
      debugPrint('Error fetching leaderboard: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载更多数据（无限滚动）
  Future<void> loadMore() async {
    if (!canLoadMore) return;

    _isLoadingMore = true;
    notifyListeners();

    _currentPage++;

    try {
      debugPrint('Loading more: range=$_currentRange, page=$_currentPage');
      final response = await _apiService.getLeaderboard(
        _currentRange,
        page: _currentPage,
      );

      if (response.success && response.list.isNotEmpty) {
        final startIndex = _allItems.length;
        _allItems.addAll(response.list);
        debugPrint('Loaded ${response.list.length} more items, total: ${_allItems.length}');
        // 异步加载新增项的视频详情
        _loadVideoDetails(startIndex, _allItems.length);
        // 更新缓存
        _saveToCache(_currentRange);
      } else if (!response.success) {
        // 加载失败，回退页码
        _currentPage--;
        debugPrint('Failed to load more: ${response.error}');
      }
    } catch (e) {
      _currentPage--;
      debugPrint('Error loading more: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// 使用 Altcha 解决方案重试
  Future<void> retryWithAltcha(String solution) async {
    await fetchLeaderboard(altchaSolution: solution);
  }

  /// 刷新排行榜（强制从网络获取）
  Future<void> refresh() async {
    // 清除当前范围的缓存时间，强制刷新
    final cacheTimeKey = _getCacheTimeKey(_currentRange);
    await _prefs.remove(cacheTimeKey);
    await fetchLeaderboard();
  }

  /// 异步加载视频详情（标题、封面等）
  Future<void> _loadVideoDetails(int startIndex, int endIndex) async {
    for (int i = startIndex; i < endIndex && i < _allItems.length; i++) {
      final item = _allItems[i];
      try {
        final videoInfo = await _apiService.getBilibiliVideoInfo(item.bvid);
        if (videoInfo != null) {
          _allItems[i] = item.copyWithVideoInfo(
            title: videoInfo.title,
            picUrl: videoInfo.pic,
            ownerName: videoInfo.ownerName,
            viewCount: videoInfo.view,
            danmakuCount: videoInfo.danmaku,
          );
          // 每加载几个就通知更新 UI
          if ((i - startIndex) % 3 == 0 || i == endIndex - 1) {
            notifyListeners();
            // 更新缓存（包含视频详情）
            if (i == endIndex - 1) {
              _saveToCache(_currentRange);
            }
          }
        }
      } catch (e) {
        // 忽略单个视频信息加载失败
        debugPrint('Failed to load video info for ${item.bvid}: $e');
      }
    }
  }

  // ==================== 向后兼容的方法（已废弃）====================

  /// 跳转到指定页（已废弃，保留兼容性）
  @Deprecated('Use infinite scroll instead')
  Future<void> goToPage(int page) async {
    // 在无限滚动模式下，此方法不再使用
  }

  /// 上一页（已废弃，保留兼容性）
  @Deprecated('Use infinite scroll instead')
  Future<void> previousPage() async {
    // 在无限滚动模式下，此方法不再使用
  }

  /// 下一页（已废弃，使用 loadMore 代替）
  @Deprecated('Use loadMore() instead')
  Future<void> nextPage() async {
    await loadMore();
  }
}
