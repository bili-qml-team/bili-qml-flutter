import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_handler/share_handler.dart';
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

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final ScrollController _scrollController = ScrollController();
  StreamSubscription? _intentSub;

  @override
  void initState() {
    super.initState();
    // 初始加载排行榜
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardProvider>().fetchLeaderboard();
    });

    // 监听滚动事件，实现无限滚动
    _scrollController.addListener(_onScroll);

    // 初始化分享监听
    _initShareListener();
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

  @override
  void dispose() {
    _intentSub?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      // 距离底部 200 像素时开始加载更多
      final provider = context.read<LeaderboardProvider>();
      if (provider.canLoadMore) {
        provider.loadMore();
      }
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
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.biliBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/icon128.png',
                width: 32,
                height: 32,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // 标题
          Text(
            'B站问号榜',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          // 搜索按钮
          IconButton(
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
        if (provider.isLoading && provider.items.isEmpty) {
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

        if (provider.error != null && provider.items.isEmpty) {
          return _buildError(context, provider);
        }

        if (provider.items.isEmpty) {
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

        return _buildGrid(context, provider);
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

  Widget _buildGrid(BuildContext context, LeaderboardProvider provider) {
    final settingsProvider = context.watch<SettingsProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 根据屏幕宽度计算列数
          int crossAxisCount = 2;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 5;
          } else if (constraints.maxWidth > 900) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth > 600) {
            crossAxisCount = 3;
          }

          return CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = provider.items[index];
                    // 排名就是 index + 1（无限滚动模式）
                    final actualRank = index + 1;
                    return VideoCard(
                      item: item,
                      rank: actualRank,
                      isRank1Custom: settingsProvider.isRank1Custom,
                      onTap: () => _openVideo(context, item.bvid, item.title),
                    );
                  }, childCount: provider.items.length),
                ),
              ),
              // 加载更多指示器
              SliverToBoxAdapter(child: _buildLoadMoreIndicator(provider)),
            ],
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
