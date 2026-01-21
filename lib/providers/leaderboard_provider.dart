import 'dart:convert';
import 'dart:math' as math;

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
  int _pendingDetailLoads = 0;

  // 分页相关
  int _currentPage = 1;
  static const int _maxPage = 10; // API 支持的最大页数
  static const int _itemsPerPage = 20; // 每页条目数
  static const int _videoDetailsBatchSize = 4;
  static const int _loadMoreThrottleMs = 400;

  // 无限滚动：存储所有已加载的数据
  final List<LeaderboardItem> _allItems = [];
  int _lastLoadMoreAt = 0;
  int _detailsRequestId = 0;

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
    _detailsRequestId++;
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

      if (!_isCacheComplete(items)) {
        await _prefs.remove(cacheKey);
        await _prefs.remove(_getCacheTimeKey(range));
        return false;
      }

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

  bool _isItemComplete(LeaderboardItem item) {
    return item.title != null &&
        item.picUrl != null &&
        item.ownerName != null &&
        item.viewCount != null &&
        item.danmakuCount != null;
  }

  bool _isCacheComplete(List<LeaderboardItem> items) {
    if (items.isEmpty) return false;

    for (final item in items) {
      if (!_isItemComplete(item)) {
        return false;
      }
    }

    return true;
  }

  /// 保存数据到缓存
  Future<void> _saveToCache(LeaderboardRange range) async {
    if (_pendingDetailLoads > 0 || !_isCacheComplete(_allItems)) {
      return;
    }

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
    final canUseCache = _allItems.isEmpty && altchaSolution == null;
    var loadedFromCache = false;

    if (canUseCache) {
      _isLoading = true;
      _error = null;
      _requiresCaptcha = false;
      notifyListeners();

      loadedFromCache = await _loadFromCache(_currentRange);
      if (loadedFromCache) {
        _isLoading = false;
        notifyListeners();
      }
    }

    await _refreshFromNetwork(
      altchaSolution: altchaSolution,
      showLoading: !loadedFromCache,
      preserveExistingItems: loadedFromCache,
    );
  }

  Future<void> _refreshFromNetwork({
    String? altchaSolution,
    bool showLoading = true,
    bool preserveExistingItems = false,
  }) async {
    final shouldPreserveItems = preserveExistingItems && _allItems.isNotEmpty;
    final existingItems = shouldPreserveItems
        ? List<LeaderboardItem>.from(_allItems)
        : null;

    if (showLoading) {
      _isLoading = true;
      _error = null;
      _requiresCaptcha = false;
      if (!shouldPreserveItems) {
        _allItems.clear();
        _detailsRequestId++;
      }
      notifyListeners();
    } else {
      _error = null;
      _requiresCaptcha = false;
    }

    if (!shouldPreserveItems) {
      _currentPage = 1;
      if (!showLoading) {
        _detailsRequestId++;
      }
    }

    try {
      debugPrint('Fetching leaderboard: range=$_currentRange, page=1');
      final response = await _apiService.getLeaderboard(
        _currentRange,
        altcha: altchaSolution,
        page: 1,
      );

      if (response.requiresCaptcha) {
        _error = '需要人机验证';
        _requiresCaptcha = !shouldPreserveItems;
        if (!shouldPreserveItems) {
          _allItems.clear();
        }
      } else if (response.success) {
        debugPrint('Received ${response.list.length} items for page 1');
        if (response.list.isNotEmpty) {
          debugPrint(
            'First 3 BVIDs: ${response.list.take(3).map((e) => e.bvid).join(", ")}',
          );
        }

        if (shouldPreserveItems && existingItems != null) {
          final preserved = existingItems.length > response.list.length
              ? existingItems.sublist(response.list.length)
              : <LeaderboardItem>[];
          _allItems
            ..clear()
            ..addAll(response.list)
            ..addAll(preserved);
        } else {
          _allItems
            ..clear()
            ..addAll(response.list);
        }

        // 校验加载的数量是否与 API 返回的数量一致
        final expectedCount = response.list.length;
        final actualCount = shouldPreserveItems
            ? response.list.length
            : _allItems.length;
        if (actualCount != expectedCount) {
          debugPrint(
            'WARNING: Leaderboard count mismatch! API returned $expectedCount items, but loaded $actualCount items. Attempting to fix...',
          );
          // 尝试修复：清空并重新添加
          if (shouldPreserveItems && existingItems != null) {
            final preserved = existingItems.length > response.list.length
                ? existingItems.sublist(response.list.length)
                : <LeaderboardItem>[];
            _allItems
              ..clear()
              ..addAll(response.list)
              ..addAll(preserved);
          } else {
            _allItems
              ..clear()
              ..addAll(response.list);
          }
          final fixedCount = shouldPreserveItems
              ? response.list.length
              : _allItems.length;
          if (fixedCount != expectedCount) {
            debugPrint(
              'Fix failed: still have $fixedCount items instead of $expectedCount',
            );
          }
        }

        final requestId = _detailsRequestId;
        final detailEnd = shouldPreserveItems
            ? response.list.length
            : _allItems.length;
        _loadVideoDetails(0, detailEnd, requestId);
        await _saveToCache(_currentRange);
      } else {
        _error = response.error ?? '获取排行榜失败';
      }
    } catch (e) {
      _error = '网络错误: ${e.toString()}';
      debugPrint('Error fetching leaderboard: $e');
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  /// 加载更多数据（无限滚动）
  Future<void> loadMore() async {
    if (!canLoadMore) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastLoadMoreAt < _loadMoreThrottleMs) return;
    _lastLoadMoreAt = now;

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
        final expectedNewItems = response.list.length;
        _allItems.addAll(response.list);
        final actualNewItems = _allItems.length - startIndex;

        // 校验加载更多的数量是否与 API 返回的数量一致
        if (actualNewItems != expectedNewItems) {
          debugPrint(
            'WARNING: LoadMore count mismatch! API returned $expectedNewItems items, but added $actualNewItems items. Attempting to fix...',
          );
          // 尝试修复：移除新增的项，重新添加
          if (_allItems.length > startIndex) {
            _allItems.removeRange(startIndex, _allItems.length);
          }
          _allItems.addAll(response.list);
          final fixedNewItems = _allItems.length - startIndex;
          if (fixedNewItems != expectedNewItems) {
            debugPrint(
              'Fix failed: added $fixedNewItems items instead of $expectedNewItems',
            );
          }
        }

        // 异步加载新增项的视频详情
        _loadVideoDetails(startIndex, _allItems.length, _detailsRequestId);
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
    final hasItems = _allItems.isNotEmpty;
    await _refreshFromNetwork(
      showLoading: !hasItems,
      preserveExistingItems: hasItems,
    );
  }

  /// 异步加载视频详情（标题、封面等）
  Future<void> _loadVideoDetails(
    int startIndex,
    int endIndex,
    int requestId,
  ) async {
    if (startIndex >= _allItems.length || endIndex <= startIndex) {
      return;
    }

    _pendingDetailLoads++;
    final cappedEnd = math.min(endIndex, _allItems.length);

    try {
      for (int i = startIndex; i < cappedEnd; i += _videoDetailsBatchSize) {
        if (requestId != _detailsRequestId) return;

        final batchEnd = math.min(i + _videoDetailsBatchSize, cappedEnd);
        final futures = <Future<void>>[];

        for (int j = i; j < batchEnd; j++) {
          futures.add(_loadVideoDetailAtIndex(j, requestId));
        }

        await Future.wait(futures);

        if (requestId != _detailsRequestId) return;
        notifyListeners();
      }
    } finally {
      _pendingDetailLoads--;
      if (_pendingDetailLoads < 0) {
        _pendingDetailLoads = 0;
      }
      if (_pendingDetailLoads == 0) {
        await _saveToCache(_currentRange);
      }
    }
  }

  Future<void> _loadVideoDetailAtIndex(int index, int requestId) async {
    if (requestId != _detailsRequestId || index >= _allItems.length) {
      return;
    }

    final item = _allItems[index];
    if (_isItemComplete(item)) {
      return;
    }

    try {
      final videoInfo = await _apiService.getBilibiliVideoInfo(item.bvid);
      if (requestId != _detailsRequestId || index >= _allItems.length) {
        return;
      }

      final currentItem = _allItems[index];
      if (videoInfo != null && currentItem.bvid == item.bvid) {
        _allItems[index] = currentItem.copyWithVideoInfo(
          title: videoInfo.title,
          picUrl: videoInfo.pic,
          ownerName: videoInfo.ownerName,
          viewCount: videoInfo.view,
          danmakuCount: videoInfo.danmaku,
        );
      }
    } catch (e) {
      // 忽略单个视频信息加载失败
      debugPrint('Failed to load video info for ${item.bvid}: $e');
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
