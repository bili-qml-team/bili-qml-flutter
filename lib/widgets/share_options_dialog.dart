import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../theme/colors.dart';

/// 分享选项对话框
class ShareOptionsDialog extends StatelessWidget {
  final LeaderboardItem item;
  final int? rank;

  const ShareOptionsDialog({super.key, required this.item, this.rank});

  /// 显示分享选项对话框
  static Future<void> show(
    BuildContext context,
    LeaderboardItem item, {
    int? rank,
  }) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => ShareOptionsDialog(item: item, rank: rank),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shareService = ShareService();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    '分享视频',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    iconSize: 20,
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            // 选项列表
            _buildOption(
              context,
              icon: Icons.copy,
              iconColor: AppColors.biliBlue,
              title: '复制 BV 号',
              subtitle: item.bvid,
              onTap: () async {
                await shareService.copyBvid(item.bvid);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _showSnackBar(context, '已复制 BV 号');
                }
              },
            ),
            _buildOption(
              context,
              icon: Icons.link,
              iconColor: Colors.green,
              title: '复制视频链接',
              subtitle: 'bilibili.com/video/${item.bvid}',
              onTap: () async {
                await shareService.copyVideoUrl(item.bvid);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _showSnackBar(context, '已复制链接');
                }
              },
            ),
            _buildOption(
              context,
              icon: Icons.content_copy,
              iconColor: Colors.orange,
              title: '复制完整信息',
              subtitle: '包含标题、排名、数据等',
              onTap: () async {
                await shareService.copyVideoInfo(item, rank: rank);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  _showSnackBar(context, '已复制完整信息');
                }
              },
            ),
            _buildOption(
              context,
              icon: Icons.share,
              iconColor: Colors.blue,
              title: '系统分享',
              subtitle: '通过其他应用分享',
              onTap: () async {
                await shareService.shareVideoInfo(item, rank: rank);
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
