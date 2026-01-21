import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/providers.dart';
import '../services/services.dart';
import '../theme/colors.dart';

/// 应用侧边栏
class AppDrawer extends StatelessWidget {
  final VoidCallback onHistoryTap;
  final VoidCallback onFavoritesTap;
  final VoidCallback onSearchBvTap;
  final VoidCallback onSettingsTap;

  const AppDrawer({
    super.key,
    required this.onHistoryTap,
    required this.onFavoritesTap,
    required this.onSearchBvTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // 头部
            _buildHeader(context, isDark),
            const Divider(height: 1),
            // 菜单列表
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildMenuItem(
                    context,
                    icon: Icons.history,
                    title: '浏览历史',
                    subtitle: '查看最近浏览的视频',
                    onTap: () {
                      Navigator.pop(context);
                      onHistoryTap();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.favorite,
                    title: '我的收藏',
                    subtitle: '管理收藏的视频',
                    onTap: () {
                      Navigator.pop(context);
                      onFavoritesTap();
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.video_library,
                    title: '搜索BV号',
                    subtitle: '通过BV号或链接查找视频',
                    onTap: () {
                      Navigator.pop(context);
                      onSearchBvTap();
                    },
                  ),
                  const Divider(),
                  _buildThemeToggle(context, isDark),
                  Consumer<PwaInstallService>(
                    builder: (context, pwaInstallService, _) {
                      if (!kIsWeb || pwaInstallService.isStandaloneMode) {
                        return const SizedBox.shrink();
                      }

                      final showInstallButton =
                          pwaInstallService.isInstallPromptAvailable;
                      final showIosTip =
                          pwaInstallService.isIosDevice &&
                          !pwaInstallService.isInstallPromptAvailable;

                      if (!showInstallButton && !showIosTip) {
                        return const SizedBox.shrink();
                      }

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (showInstallButton)
                            _buildMenuItem(
                              context,
                              icon: Icons.download,
                              title: '安装应用',
                              subtitle: '添加到桌面或主屏幕',
                              onTap: () {
                                Navigator.pop(context);
                                pwaInstallService.promptInstall();
                              },
                            ),
                          if (showIosTip) _buildIosInstallTip(context, isDark),
                        ],
                      );
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.group_add,
                    title: '加入QQ群',
                    subtitle: '点击加入交流群',
                    onTap: () async {
                      Navigator.pop(context);
                      final uri = Uri.parse('https://qm.qq.com/q/Yc8xTHKZqA');
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(
                          uri,
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                  ),
                  _buildMenuItem(
                    context,
                    icon: Icons.settings,
                    title: '设置',
                    subtitle: '自定义API、用户ID等',
                    onTap: () {
                      Navigator.pop(context);
                      onSettingsTap();
                    },
                  ),
                ],
              ),
            ),
            // 底部版本信息
            _buildFooter(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.biliBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Image.asset(
                'assets/icons/icon128.png',
                width: 36,
                height: 36,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'B站问号榜',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '发现有趣的视频',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ListTile(
      leading: Icon(
        icon,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
      ),
      title: Text(title),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
        ),
      ),
      onTap: onTap,
    );
  }

  Widget _buildThemeToggle(BuildContext context, bool isDark) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final currentMode = themeProvider.themeMode;
        String modeText;
        IconData modeIcon;

        switch (currentMode) {
          case ThemeMode.system:
            modeText = '跟随系统';
            modeIcon = Icons.brightness_auto;
            break;
          case ThemeMode.light:
            modeText = '浅色模式';
            modeIcon = Icons.light_mode;
            break;
          case ThemeMode.dark:
            modeText = '深色模式';
            modeIcon = Icons.dark_mode;
            break;
        }

        return ListTile(
          leading: Icon(
            modeIcon,
            color: isDark
                ? AppColors.darkTextSecondary
                : AppColors.lightTextSecondary,
          ),
          title: const Text('主题'),
          subtitle: Text(
            modeText,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
          ),
          trailing: PopupMenuButton<ThemeMode>(
            initialValue: currentMode,
            onSelected: (mode) => themeProvider.setThemeMode(mode),
            itemBuilder: (context) => [
              const PopupMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
              const PopupMenuItem(value: ThemeMode.light, child: Text('浅色模式')),
              const PopupMenuItem(value: ThemeMode.dark, child: Text('深色模式')),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.biliBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    modeText,
                    style: TextStyle(fontSize: 12, color: AppColors.biliBlue),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 16,
                    color: AppColors.biliBlue,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildIosInstallTip(BuildContext context, bool isDark) {
    return ListTile(
      leading: Icon(
        Icons.ios_share,
        color: isDark
            ? AppColors.darkTextSecondary
            : AppColors.lightTextSecondary,
      ),
      title: const Text('iOS 手动安装'),
      subtitle: Text(
        'Safari 点分享按钮，选择“添加到主屏幕”',
        style: TextStyle(
          fontSize: 12,
          color: isDark
              ? AppColors.darkTextTertiary
              : AppColors.lightTextTertiary,
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: GestureDetector(
        onTap: () async {
          final uri = Uri.parse(
            'https://github.com/bili-qml-team/bili-qml-flutter',
          );
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.code,
              size: 14,
              color: isDark
                  ? AppColors.darkTextTertiary
                  : AppColors.lightTextTertiary,
            ),
            const SizedBox(width: 4),
            Text(
              'GitHub',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
