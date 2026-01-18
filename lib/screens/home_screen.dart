import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  @override
  void initState() {
    super.initState();
    // 初始加载排行榜
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LeaderboardProvider>().fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
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
          const SizedBox(width: 12),
          // 按钮区域 - 使用 Expanded + SingleChildScrollView 处理溢出
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // 浏览历史按钮
                  IconButton(
                    icon: Icon(
                      Icons.history,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onPressed: () => _openHistory(context),
                    tooltip: '浏览历史',
                  ),
                  // 收藏按钮
                  IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onPressed: () => _openFavorites(context),
                    tooltip: '我的收藏',
                  ),
                  // BV号搜索按钮
                  IconButton(
                    icon: Icon(
                      Icons.video_library,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onPressed: () => _showBvSearchDialog(context),
                    tooltip: '搜索BV号',
                  ),
                  // 主题切换按钮
                  IconButton(
                    icon: Icon(
                      isDark ? Icons.light_mode : Icons.dark_mode,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onPressed: () => _toggleTheme(context),
                    tooltip: '切换主题',
                  ),
                  // 设置按钮
                  IconButton(
                    icon: Icon(
                      Icons.settings,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                    onPressed: () => _openSettings(context),
                    tooltip: '设置',
                  ),
                ],
              ),
            ),
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

        // 将网格和分页控件放在 Column 中
        return Column(
          children: [
            Expanded(child: _buildGrid(context, provider)),
            _buildPaginationControls(context, provider),
          ],
        );
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
    // 假设每页20条数据（基于常见API设计）
    const int itemsPerPage = 20;

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

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemCount: provider.items.length,
            itemBuilder: (context, index) {
              final item = provider.items[index];
              // 根据当前页码和索引计算真实排名
              final actualRank =
                  (provider.currentPage - 1) * itemsPerPage + index + 1;
              return VideoCard(
                item: item,
                rank: actualRank,
                isRank1Custom: settingsProvider.isRank1Custom,
                onTap: () => _openVideo(context, item.bvid, item.title),
              );
            },
          );
        },
      ),
    );
  }

  void _toggleTheme(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final currentMode = themeProvider.themeMode;

    ThemeMode newMode;
    switch (currentMode) {
      case ThemeMode.system:
        final brightness = MediaQuery.of(context).platformBrightness;
        newMode = brightness == Brightness.dark
            ? ThemeMode.light
            : ThemeMode.dark;
        break;
      case ThemeMode.light:
        newMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        newMode = ThemeMode.light;
        break;
    }

    themeProvider.setThemeMode(newMode);
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

  /// 构建分页控件
  Widget _buildPaginationControls(
    BuildContext context,
    LeaderboardProvider provider,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black12 : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 上一页按钮
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: provider.canGoPreviousPage && !provider.isLoading
                ? () => provider.previousPage()
                : null,
            tooltip: '上一页',
          ),
          const SizedBox(width: 8),
          // 页码显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.biliBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${provider.currentPage}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.biliBlue,
                  ),
                ),
                Text(
                  ' / ${provider.maxPage}',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // 下一页按钮
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: provider.canGoNextPage && !provider.isLoading
                ? () => provider.nextPage()
                : null,
            tooltip: '下一页',
          ),
        ],
      ),
    );
  }
}
