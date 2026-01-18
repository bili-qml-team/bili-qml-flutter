import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
          const Spacer(),
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
              return VideoCard(
                item: item,
                rank: index + 1,
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

    // Check if it's a b23.tv short link
    if (_isB23ShortLink(trimmedInput)) {
      // Show loading indicator
      Navigator.of(dialogContext).pop();
      _showLoadingDialog();

      try {
        final resolvedUrl = await _resolveB23ShortLink(trimmedInput);
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog

        if (resolvedUrl != null) {
          final bvid = _parseBvid(resolvedUrl);
          if (bvid != null && bvid.isNotEmpty) {
            _openVideo(context, bvid, null);
            return;
          }
        }
        _showErrorSnackBar('无法解析短链接');
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop(); // Close loading dialog
        _showErrorSnackBar('解析短链接失败: $e');
      }
      return;
    }

    // Regular BV number or bilibili URL
    final bvid = _parseBvid(trimmedInput);
    if (bvid != null && bvid.isNotEmpty) {
      Navigator.of(dialogContext).pop();
      _openVideo(context, bvid, null);
    } else {
      _showErrorSnackBar('无效的 BV 号或链接');
    }
  }

  bool _isB23ShortLink(String input) {
    return input.contains('b23.tv/') || input.contains('b23.com/');
  }

  /// Extract the b23.tv/b23.com URL from text that may contain other content
  /// e.g., "【差评率100%的自助火锅-哔哩哔哩】 https://b23.tv/sne4c22"
  String? _extractB23Url(String input) {
    // Match http(s)://b23.tv/xxx or http(s)://b23.com/xxx
    final urlPattern = RegExp(
      r'https?://b23\.(tv|com)/[a-zA-Z0-9]+',
      caseSensitive: false,
    );
    final match = urlPattern.firstMatch(input);
    if (match != null) {
      return match.group(0);
    }

    // Also match without http:// prefix like "b23.tv/xxx"
    final shortPattern = RegExp(
      r'b23\.(tv|com)/[a-zA-Z0-9]+',
      caseSensitive: false,
    );
    final shortMatch = shortPattern.firstMatch(input);
    if (shortMatch != null) {
      return 'https://${shortMatch.group(0)}';
    }

    return null;
  }

  Future<String?> _resolveB23ShortLink(String shortUrl) async {
    try {
      // Extract the actual URL from text that may contain other content
      final url = _extractB23Url(shortUrl) ?? shortUrl;

      // Ensure the URL has a scheme
      String processedUrl = url;
      if (!processedUrl.startsWith('http://') &&
          !processedUrl.startsWith('https://')) {
        processedUrl = 'https://$processedUrl';
      }

      // Make a HEAD request to follow redirects
      final client = http.Client();
      try {
        final request = http.Request('GET', Uri.parse(processedUrl));
        request.followRedirects = false;

        final streamedResponse = await client.send(request);

        // Check for redirect
        if (streamedResponse.statusCode >= 300 &&
            streamedResponse.statusCode < 400) {
          final location = streamedResponse.headers['location'];
          if (location != null) {
            return location;
          }
        }

        // If no redirect, try to get final URL from response
        // Some short links might redirect via JavaScript, so we try the full request
        final response = await http.get(Uri.parse(processedUrl));
        // Check response body for video URL pattern
        final bvPattern = RegExp(
          r'bilibili\.com/video/(BV[a-zA-Z0-9]{10,12})',
          caseSensitive: false,
        );
        final match = bvPattern.firstMatch(response.body);
        if (match != null) {
          return 'https://www.bilibili.com/video/${match.group(1)}';
        }

        return null;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error resolving short link: $e');
      return null;
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

  String? _parseBvid(String input) {
    if (input.isEmpty) return null;

    // Direct BV number (with or without "BV" prefix)
    // BV numbers are typically 10-12 alphanumeric characters after "BV"
    final bvPattern = RegExp(
      r'^(BV)?([a-zA-Z0-9]{10,12})$',
      caseSensitive: false,
    );
    final directMatch = bvPattern.firstMatch(input);
    if (directMatch != null) {
      final bv = directMatch.group(2);
      return bv != null ? 'BV$bv' : null;
    }

    // URL pattern: handles various formats like:
    // - https://www.bilibili.com/video/BV1QMrhBkE8r/
    // - https://www.bilibili.com/video/BV1QMrhBkE8r/?share_source=copy_web
    // - https://www.bilibili.com/video/BV1qtrfBYEEN?t=1
    // The pattern captures BV + alphanumeric chars until / or ? or end of string
    final urlPattern = RegExp(
      r'bilibili\.com/video/(BV[a-zA-Z0-9]+)',
      caseSensitive: false,
    );
    final urlMatch = urlPattern.firstMatch(input);
    if (urlMatch != null) {
      return urlMatch.group(1);
    }

    // Try to extract BV from any text containing it
    // Matches BV followed by alphanumeric chars, stopping at non-alphanumeric
    final anyBvPattern = RegExp(r'(BV[a-zA-Z0-9]+)', caseSensitive: false);
    final anyMatch = anyBvPattern.firstMatch(input);
    if (anyMatch != null) {
      return anyMatch.group(1);
    }

    return null;
  }
}
