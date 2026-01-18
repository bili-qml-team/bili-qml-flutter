import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import '../models/models.dart';
import '../services/services.dart';

/// 排行榜状态管理
class LeaderboardProvider extends ChangeNotifier {
  final ApiService _apiService;

  LeaderboardRange _currentRange = LeaderboardRange.realtime;
  List<LeaderboardItem> _items = [];
  bool _isLoading = false;
  String? _error;
  bool _requiresCaptcha = false;

  // 分页相关
  int _currentPage = 1;
  static const int _maxPage = 10; // API 支持的最大页数

  // 搜索/筛选相关
  String? _searchQuery;
  String? _upNameFilter;

  LeaderboardProvider(this._apiService);

  // Getters
  LeaderboardRange get currentRange => _currentRange;
  List<LeaderboardItem> get items => _getFilteredItems();
  List<LeaderboardItem> get allItems => _items; // 原始数据
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get requiresCaptcha => _requiresCaptcha;
  String? get searchQuery => _searchQuery;
  String? get upNameFilter => _upNameFilter;
  bool get hasActiveFilters => _searchQuery != null || _upNameFilter != null;

  // 分页相关 getters
  int get currentPage => _currentPage;
  int get maxPage => _maxPage;
  bool get canGoPreviousPage => _currentPage > 1;
  bool get canGoNextPage => _currentPage < _maxPage;

  /// 获取过滤后的列表
  List<LeaderboardItem> _getFilteredItems() {
    var filtered = _items;

    // 按关键词搜索（标题）
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      final query = _searchQuery!.toLowerCase();
      filtered = filtered.where((item) {
        return item.title?.toLowerCase().contains(query) ?? false;
      }).toList();
    }

    // 按 UP主 筛选
    if (_upNameFilter != null && _upNameFilter!.isNotEmpty) {
      final filter = _upNameFilter!.toLowerCase();
      filtered = filtered.where((item) {
        return item.ownerName?.toLowerCase().contains(filter) ?? false;
      }).toList();
    }

    return filtered;
  }

  /// 设置搜索关键词
  void setSearchQuery(String? query) {
    _searchQuery = query?.trim();
    notifyListeners();
  }

  /// 设置 UP主 筛选
  void setUpNameFilter(String? upName) {
    _upNameFilter = upName?.trim();
    notifyListeners();
  }

  /// 应用筛选器
  void applyFilters({String? keyword, String? upName}) {
    _searchQuery = keyword?.trim();
    _upNameFilter = upName?.trim();
    notifyListeners();
  }

  /// 清除所有筛选
  void clearFilters() {
    _searchQuery = null;
    _upNameFilter = null;
    notifyListeners();
  }

  /// 切换时间范围
  Future<void> setRange(LeaderboardRange range) async {
    if (_currentRange == range && _items.isNotEmpty) return;

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
      final response = await _apiService.getLeaderboard(
        _currentRange,
        altcha: altchaSolution,
        page: _currentPage,
      );

      if (response.requiresCaptcha) {
        _requiresCaptcha = true;
        _error = '需要人机验证';
      } else if (response.success) {
        _items = response.list;
        // 异步加载视频详情
        _loadVideoDetails();
      } else {
        _error = response.error ?? '获取排行榜失败';
      }
    } catch (e) {
      _error = '网络错误: ${e.toString()}';
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
    for (int i = 0; i < _items.length; i++) {
      final item = _items[i];
      try {
        final videoInfo = await _apiService.getBilibiliVideoInfo(item.bvid);
        if (videoInfo != null) {
          _items[i] = item.copyWithVideoInfo(
            title: videoInfo.title,
            picUrl: videoInfo.pic,
            ownerName: videoInfo.ownerName,
            viewCount: videoInfo.view,
            danmakuCount: videoInfo.danmaku,
          );
          // 每加载几个就通知更新 UI
          if (i % 3 == 0 || i == _items.length - 1) {
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
