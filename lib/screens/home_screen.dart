import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_handler/share_handler.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import '../theme/colors.dart';
import 'video_screen.dart';
import 'settings_screen.dart';
import 'favorites_screen.dart';
import 'history_screen.dart';

/// 主页 - 排行榜
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  static OverlayEntry? _currentToast;

  /// 显示右下角 Toast 通知
  static void showBottomRightToast(BuildContext context, String message) {
    _currentToast?.remove();
    _currentToast = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        onDismiss: () {
          if (_currentToast == entry) {
            _currentToast?.remove();
            _currentToast = null;
          }
        },
      ),
    );

    _currentToast = entry;
    Overlay.of(context).insert(entry);
  }

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _intentSub;

  /// 上次触发加载的时间，用于节流
  int _lastLoadTriggerTime = 0;

  /// 节流间隔，单位毫秒
  static const int _loadThrottleMs = 300;

  @override
  void initState() {
    super.initState();
    // 初始加载排行榜
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardProvider>().fetchLeaderboard();
      // 检查更新（仅非 Web 端）
      _checkForUpdate();
      _handleWebParams();
    });

    // 初始化分享监听
    _initShareListener();
  }

  /// 检查应用更新
  Future<void> _checkForUpdate() async {
    final updateService = UpdateService();
    final releaseInfo = await updateService.checkForUpdate();

    if (releaseInfo != null && mounted) {
      UpdateDialog.show(context, releaseInfo);
    }
  }

  /// 初始化分享监听
  Future<void> _initShareListener() async {
    // 1. 处理应用冷启动时的分享内容
    try {
      final initialShared = await ShareHandler.instance.getInitialSharedMedia();
      if (initialShared != null) {
        _processSharedContent(initialShared);
        // 清除初始分享内容，防止热重载或重新初始化时重复处理
        await ShareHandler.instance.resetInitialSharedMedia();
      }
    } catch (e) {
      debugPrint('获取初始分享内容失败: $e');
    }

    // 2. 监听运行时的分享内容
    _intentSub = ShareHandler.instance.sharedMediaStream.listen(
      (SharedMedia value) {
        _processSharedMedia(value);
      },
      onError: (err) {
        debugPrint('分享接收错误: $err');
      },
    );
  }

  /// 处理 SharedMedia 对象（来自 Stream）
  void _processSharedMedia(SharedMedia media) {
    if (media.content != null && media.content!.isNotEmpty) {
      // 优先使用 content (通常是文本或链接)
      _handleSharedText(media.content!);
    } else if (media.attachments != null && media.attachments!.isNotEmpty) {
      // 如果有附件，尝试从附件路径中获取信息（虽然当前只处理文本）
      // 这里暂时不需要专门处理文件，我们的场景主要是 BV 号文本
    }
  }

  /// 处理 initialShared 对象（结构可能不同，视插件版本而定，share_handler 统一使用 SharedMedia）
  void _processSharedContent(SharedMedia media) {
    _processSharedMedia(media);
  }

  /// 处理分享的文本
  Future<void> _handleSharedText(String text) async {
    if (text.isEmpty) return;
    debugPrint('收到分享内容: $text');
    await _parseAndNavigate(text);
  }

  /// 解析分享内容并导航
  Future<void> _parseAndNavigate(String text) async {
    final bvidParser = BvidParserService();

    // 显示加载提示
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('正在解析分享内容...'),
            ],
          ),
        ),
      );
    }

    try {
      String? bvid;

      // 检查是否为短链接
      if (bvidParser.isShortLink(text)) {
        bvid = await bvidParser.parseAsync(text);
      } else {
        bvid = bvidParser.parseBvid(text);
      }

      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭加载对话框

      if (bvid != null && bvid.isNotEmpty) {
        // 成功解析，跳转到视频详情页
        _openVideo(context, bvid, null);
      } else {
        // 解析失败，显示提示
        _showErrorSnackBar('无法从分享内容中解析出BV号');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // 关闭加载对话框
      _showErrorSnackBar('解析分享内容失败: $e');
    }
  }


  /// 处理滚动事件，检测是否需要加载更多
  ///
  /// 优化点：
  /// 1. 使用 NotificationListener 在 Widget 层处理滚动
  /// 2. 动态计算预加载阈值为视口高度的 50%
  /// 3. 添加节流机制避免短时间内重复触发
  bool _handleScrollNotification(ScrollNotification notification) {
    // 只处理滚动更新通知
    if (notification is ScrollUpdateNotification) {
      final metrics = notification.metrics;

      // 计算动态预加载阈值：视口高度的 50%，最小 200 像素
      final viewportHeight = metrics.viewportDimension;
      final preloadThreshold = (viewportHeight * 0.5).clamp(200.0, 600.0);

      // 检查是否接近底部
      final distanceToBottom = metrics.maxScrollExtent - metrics.pixels;

      if (distanceToBottom <= preloadThreshold) {
        _tryLoadMore();
      }
    }
    // 返回 false 让通知继续传递
    return false;
  }

  /// 尝试加载更多数据，带节流
  void _tryLoadMore() {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 节流：避免短时间内重复触发
    if (now - _lastLoadTriggerTime < _loadThrottleMs) {
      return;
    }

    final provider = context.read<LeaderboardProvider>();
    if (provider.canLoadMore) {
      _lastLoadTriggerTime = now;
      provider.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      endDrawer: AppDrawer(
        onHistoryTap: () => _openHistory(context),
        onFavoritesTap: () => _openFavorites(context),
        onSearchBvTap: () => _showBvSearchDialog(context),
        onSettingsTap: () => _openSettings(context),
      ),
      body: SafeArea(
        child: ResponsivePageContainer(
          maxWidth: 1680,
          child: Column(
            children: [
              // 顶部区域
              _buildHeader(context, isDark),
              // 时间范围选项卡
              Consumer<LeaderboardProvider>(
                builder: (context, provider, _) {
                  return LeaderboardTabs(
                    currentRange: provider.currentRange,
                    onRangeChanged: (range) => provider.setRange(range),
                    onSearchPressed: () => SearchBottomSheet.show(context),
                  );
                },
              ),
              // 排行榜列表
              Expanded(child: _buildLeaderboardContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= ResponsiveBreakpoints.desktop;
    final logoSize = isDesktop ? 44.0 : 40.0;
    final iconButtonSize = isDesktop ? 42.0 : 40.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 20 : 16,
        vertical: isDesktop ? 14 : 12,
      ),
      child: Row(
        children: [
          // Logo
          Container(
            width: logoSize,
            height: logoSize,
            decoration: BoxDecoration(
              color: AppColors.biliBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/icon128.png',
                width: isDesktop ? 34 : 32,
                height: isDesktop ? 34 : 32,
              ),
            ),
          ),
          SizedBox(width: isDesktop ? 14 : 12),
          // 标题
          Text(
            'B站问号榜',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isDesktop ? 27 : null,
              letterSpacing: isDesktop ? 0.2 : null,
            ),
          ),
          const Spacer(),
          // 搜索按钮
          IconButton(
            constraints: BoxConstraints.tightFor(
              width: iconButtonSize,
              height: iconButtonSize,
            ),
            icon: Icon(
              Icons.search,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: () => _showBvSearchDialog(context),
            tooltip: '搜索BV号',
          ),
          // 菜单按钮
          IconButton(
            constraints: BoxConstraints.tightFor(
              width: iconButtonSize,
              height: iconButtonSize,
            ),
            icon: Icon(
              Icons.menu,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            tooltip: '菜单',
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardContent() {
    return Consumer<LeaderboardProvider>(
      builder: (context, provider, _) {
        final items = provider.items;
        if (provider.isLoading && items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在获取排行榜数据...'),
              ],
            ),
          );
        }

        if (provider.requiresCaptcha) {
          return _buildCaptchaRequired(context, provider);
        }

        if (provider.error != null && items.isEmpty) {
          return _buildError(context, provider);
        }

        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('📭', style: TextStyle(fontSize: 48)),
                SizedBox(height: 16),
                Text('暂无数据'),
              ],
            ),
          );
        }

        return _buildGrid(context, provider, items);
      },
    );
  }

  Widget _buildCaptchaRequired(
    BuildContext context,
    LeaderboardProvider provider,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🤖', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          const Text('需要人机验证'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final apiService = context.read<ApiService>();
              final altchaService = AltchaService(apiService);
              final solution = await AltchaDialog.show(context, altchaService);
              if (solution != null && context.mounted) {
                provider.retryWithAltcha(solution);
              }
            },
            child: const Text('开始验证'),
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, LeaderboardProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            provider.error ?? '获取失败',
            style: const TextStyle(color: AppColors.error),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.refresh(),
            child: const Text('重试'),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    LeaderboardProvider provider,
    List<LeaderboardItem> items,
  ) {
    final settingsProvider = context.watch<SettingsProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final isDesktop = width >= ResponsiveBreakpoints.desktop;
          final minTileWidth = width >= ResponsiveBreakpoints.desktop
              ? 300.0
              : width >= ResponsiveBreakpoints.tablet
              ? 240.0
              : 175.0;
          final crossAxisCount = ResponsiveBreakpoints.adaptiveColumnCount(
            width,
            minTileWidth: minTileWidth,
            minCount: 2,
            maxCount: 7,
          );
          final gridSpacing = isDesktop ? 16.0 : 12.0;
          final childAspectRatio = isDesktop ? 0.82 : 0.75;
          final highPriorityCount = crossAxisCount * 2;

          return NotificationListener<ScrollNotification>(
            onNotification: _handleScrollNotification,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.symmetric(
                    horizontal: gridSpacing,
                    vertical: 16,
                  ),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: gridSpacing,
                      mainAxisSpacing: gridSpacing,
                      childAspectRatio: childAspectRatio,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = items[index];
                      // 排名就是 index + 1（无限滚动模式）
                      final actualRank = index + 1;
                      return VideoCard(
                        item: item,
                        rank: actualRank,
                        isRank1Custom: settingsProvider.isRank1Custom,
                        isHighPriorityImage: index < highPriorityCount,
                        onTap: () => _openVideo(context, item.bvid, item.title),
                      );
                    }, childCount: items.length),
                  ),
                ),
                // 加载更多指示器
                SliverToBoxAdapter(child: _buildLoadMoreIndicator(provider)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreIndicator(LeaderboardProvider provider) {
    if (provider.isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('加载更多...'),
          ],
        ),
      );
    }

    if (!provider.hasMore && provider.items.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        alignment: Alignment.center,
        child: Text(
          '已加载全部 ${provider.items.length} 条数据',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
          ),
        ),
      );
    }

    return const SizedBox(height: 16);
  }

  void _openSettings(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _openFavorites(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const FavoritesScreen()));
  }

  void _openHistory(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const HistoryScreen()));
  }

  void _openVideo(BuildContext context, String bvid, String? title) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VideoScreen(bvid: bvid, title: title),
      ),
    );
  }

  void _showBvSearchDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('查找视频'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('请输入 BV 号或视频链接', style: TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'BV 号或链接',
                hintText: '例如: BV1SnrGBQE2U 或完整链接',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              onSubmitted: (_) =>
                  _handleSearchSubmit(dialogContext, controller.text),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () =>
                _handleSearchSubmit(dialogContext, controller.text),
            child: const Text('查找'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSearchSubmit(
    BuildContext dialogContext,
    String input,
  ) async {
    final trimmedInput = input.trim();
    final bvidParser = BvidParserService();

    // 检查是否为短链接
    if (bvidParser.isShortLink(trimmedInput)) {
      // 关闭输入对话框并显示加载提示
      Navigator.of(dialogContext).pop();
      _showLoadingDialog();

      try {
        // 使用 BvidParserService 的异步解析方法
        final bvid = await bvidParser.parseAsync(trimmedInput);

        if (!mounted) return;
        Navigator.of(context).pop(); // 关闭加载对话框

        if (bvid != null && bvid.isNotEmpty) {
          _openVideo(context, bvid, null);
          return;
        }

        _showErrorSnackBar('无法解析短链接');
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // 关闭加载对话框
        _showErrorSnackBar('解析短链接失败: $e');
      }
      return;
    }

    // 普通BV号或B站链接
    final bvid = bvidParser.parseBvid(trimmedInput);
    if (bvid != null && bvid.isNotEmpty) {
      Navigator.of(dialogContext).pop();
      _openVideo(context, bvid, null);
    } else {
      _showErrorSnackBar('无效的 BV 号或链接');
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('正在解析短链接...'),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    StatusFeedback.error(context, message);
  }

  Future<void> _handleWebParams() async {
    if (!kIsWeb) return;

    final queryParams = Uri.base.queryParameters;
    final uid = queryParams['uid']?.trim();
    final token = queryParams['token']?.trim();
    final from = queryParams['from']?.trim();

    final storageService = context.read<StorageService>();
    final settingsProvider = context.read<SettingsProvider>();
    final hasUid = uid != null && uid.isNotEmpty;
    final hasToken = token != null && token.isNotEmpty;
    var updatedUid = false;
    var updatedToken = false;

    if (hasUid) {
      // Web: always apply uid from query params (overwrite stored value)
      await settingsProvider.setUserId(uid);
      updatedUid = true;
      if (!mounted) return;
    }

    if (from == 'extension') {
      if (hasToken) {
        await settingsProvider.setVoteToken(token);
        updatedToken = true;
      } else {
        final dismissed = storageService.getWebTokenGuideDismissed();
        if (!dismissed && mounted) {
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (context) => const TokenGuideDialog(),
          );
        }
      }
    }

    if (mounted && (updatedUid || updatedToken)) {
      final message = updatedUid && updatedToken
          ? 'UID 与 Token 已更新'
          : updatedUid
              ? 'UID 已更新'
              : 'Token 已更新';
      HomeScreen.showBottomRightToast(context, message);
    }
  }
}

/// 右下角 Toast 组件
class _ToastWidget extends StatefulWidget {
  final String message;
  final VoidCallback onDismiss;

  const _ToastWidget({
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    // Slide from right (Offset(1, 0) means start 100% to the right)
    _slide = Tween<Offset>(begin: const Offset(1.0, 0.0), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();

    // Auto dismiss after 5 seconds
    _timer = Timer(const Duration(seconds: 5), _dismiss);
  }

  void _dismiss() {
    _timer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) => widget.onDismiss());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slide,
          child: FadeTransition(
            opacity: _opacity,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 300),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.inverseSurface,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.message,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onInverseSurface,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: _dismiss,
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Theme.of(context).colorScheme.onInverseSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
