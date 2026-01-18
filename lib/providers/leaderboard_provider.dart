import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import '../models/models.dart';
import '../services/services.dart';
import 'base/filterable_provider.dart';

/// 排行榜状态管理
class LeaderboardProvider extends FilterableProvider<LeaderboardItem> {
  final ApiService _apiService;

  LeaderboardRange _currentRange = LeaderboardRange.realtime;
  bool _isLoading = false;
  String? _error;
  bool _requiresCaptcha = false;

  // 分页相关
  int _currentPage = 1;
  static const int _maxPage = 10; // API 支持的最大页数

  LeaderboardProvider(this._apiService);

  // Getters
  LeaderboardRange get currentRange => _currentRange;
  List<LeaderboardItem> get allItems => rawItems; // 原始数据（向后兼容）
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get requiresCaptcha => _requiresCaptcha;

  // 向后兼容的 getters（已废弃，使用基类的 criteria）
  @Deprecated('Use criteria.keyword instead')
  String? get searchQuery => criteria.keyword;

  @Deprecated('Use criteria.upName instead')
  String? get upNameFilter => criteria.upName;

  // 分页相关 getters
  int get currentPage => _currentPage;
  int get maxPage => _maxPage;
  bool get canGoPreviousPage => _currentPage > 1;
  bool get canGoNextPage => _currentPage < _maxPage;

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
    if (_currentRange == range && rawItems.isNotEmpty) return;

    _currentRange = range;
    _currentPage = 1; // 切换范围时重置到第一页
    notifyListeners();
    await fetchLeaderboard();
  }

  /// 跳转到指定页
  Future<void> goToPage(int page) async {
    if (page < 1 || page > _maxPage || page == _currentPage) return;

    _currentPage = page;
    notifyListeners();
    await fetchLeaderboard();
  }

  /// 上一页
  Future<void> previousPage() async {
    if (!canGoPreviousPage) return;
    await goToPage(_currentPage - 1);
  }

  /// 下一页
  Future<void> nextPage() async {
    if (!canGoNextPage) return;
    await goToPage(_currentPage + 1);
  }

  /// 获取排行榜数据
  Future<void> fetchLeaderboard({String? altchaSolution}) async {
    _isLoading = true;
    _error = null;
    _requiresCaptcha = false;
    notifyListeners();

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
        // 打印前3个BVID用于调试
        if (response.list.isNotEmpty) {
          debugPrint('First 3 BVIDs: ${response.list.take(3).map((e) => e.bvid).join(", ")}');
        }
        rawItems = response.list; // 使用基类的 rawItems setter
        // 异步加载视频详情
        _loadVideoDetails();
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

  /// 使用 Altcha 解决方案重试
  Future<void> retryWithAltcha(String solution) async {
    await fetchLeaderboard(altchaSolution: solution);
  }

  /// 刷新排行榜
  Future<void> refresh() async {
    await fetchLeaderboard();
  }

  /// 异步加载视频详情（标题、封面等）
  Future<void> _loadVideoDetails() async {
    final items = rawItems; // 获取当前原始数据的引用

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      try {
        final videoInfo = await _apiService.getBilibiliVideoInfo(item.bvid);
        if (videoInfo != null) {
          items[i] = item.copyWithVideoInfo(
            title: videoInfo.title,
            picUrl: videoInfo.pic,
            ownerName: videoInfo.ownerName,
            viewCount: videoInfo.view,
            danmakuCount: videoInfo.danmaku,
          );
          // 每加载几个就通知更新 UI
          if (i % 3 == 0 || i == items.length - 1) {
            notifyListeners();
          }
        }
      } catch (e) {
        // 忽略单个视频信息加载失败
        debugPrint('Failed to load video info for ${item.bvid}: $e');
      }
    }
  }
}
