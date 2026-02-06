import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/constants.dart';
import '../services/update_service.dart';
import '../theme/colors.dart';

/// 更新提示对话框
class UpdateDialog extends StatelessWidget {
  final ReleaseInfo releaseInfo;

  const UpdateDialog({super.key, required this.releaseInfo});

  /// 显示更新对话框
  static Future<void> show(BuildContext context, ReleaseInfo releaseInfo) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => UpdateDialog(releaseInfo: releaseInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark
          ? AppColors.darkCardBackgroundElevated
          : AppColors.lightCardBackground,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.biliBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text('🎉', style: TextStyle(fontSize: 24)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '发现新版本',
                    style:
                        theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    'v${releaseInfo.version}',
                    style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.normal,
                    color: AppColors.biliBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (releaseInfo.body.isNotEmpty) ...[
              Text(
                '更新内容：',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? AppColors.darkTextPrimary
                      : AppColors.lightTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkCardBackground
                      : AppColors.lightBackground,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),
                constraints: const BoxConstraints(maxHeight: 200),
                child: SingleChildScrollView(
                  child: Text(
                    releaseInfo.body,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.lightTextSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            // GitHub 下载按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openGitHub(context),
                icon: const Icon(Icons.download),
                label: const Text('前往 GitHub 下载'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.biliBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // 提示文字
            Text(
              '如无法访问 GitHub，可加入 QQ 群获取更新',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.darkTextTertiary
                    : AppColors.lightTextTertiary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // QQ 群按钮
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openQQGroup(context),
                icon: const Icon(Icons.group),
                label: const Text('加入 QQ 群'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                  textStyle: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.biliBlue,
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
          child: const Text('稍后提醒'),
        ),
      ],
    );
  }

  Future<void> _openGitHub(BuildContext context) async {
    final uri = Uri.parse(GitHubConfig.releasesPageUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openQQGroup(BuildContext context) async {
    final uri = Uri.parse(GitHubConfig.qqGroupUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
