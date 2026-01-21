import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../services/image_proxy_service.dart';
import '../theme/colors.dart';
import '../widgets/widgets.dart';
import 'video_screen.dart';

/// 浏览历史页面
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    // 加载历史记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('浏览历史'),
        actions: [
          // 筛选按钮
          Consumer<HistoryProvider>(
            builder: (context, provider, _) {
              if (provider.history.isEmpty && !provider.hasActiveFilters) {
                return const SizedBox.shrink();
              }
              return IconButton(
                icon: Icon(
                  Icons.filter_list,
                  color: provider.hasActiveFilters ? AppColors.biliBlue : null,
                ),
                onPressed: () => SearchBottomSheet.show(context),
                tooltip: '筛选',
              );
            },
          ),
          // 清空历史按钮
          Consumer<HistoryProvider>(
            builder: (context, provider, _) {
              if (provider.history.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _showClearDialog(context),
                tooltip: '清空历史',
              );
            },
          ),
        ],
      ),
      body: Consumer<HistoryProvider>(
        builder: (context, provider, _) {
          // 加载中
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 空状态
          if (provider.history.isEmpty) {
            return _buildEmptyState(isDark);
          }

          // 历史记录列表（按日期分组）
          final grouped = provider.getGroupedByDate();
          return RefreshIndicator(
            onRefresh: () => provider.loadHistory(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: grouped.length,
              itemBuilder: (context, index) {
                final dateKey = grouped.keys.elementAt(index);
                final items = grouped[dateKey]!;
                return _buildDateGroup(context, dateKey, items, isDark);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 80,
            color: isDark
                ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                : AppColors.lightTextSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无浏览历史',
            style: TextStyle(
              fontSize: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '观看过的视频会显示在这里',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                  : AppColors.lightTextSecondary.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateGroup(
    BuildContext context,
    String dateKey,
    List<HistoryItem> items,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 日期标题
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            dateKey,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
        ),
        // 该日期的历史记录
        ...items.map((item) => _buildHistoryCard(context, item, isDark)),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    HistoryItem item,
    bool isDark,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => VideoScreen(bvid: item.bvid)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // 封面图
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: SizedBox(
                  width: 120,
                  height: 75,
                  child: item.picUrl != null && item.picUrl!.isNotEmpty
                      ? Image.network(
                          ImageProxyService.getProxiedImageUrl(
                            context,
                            item.picUrl,
                          ),
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildPlaceholder(isDark),
                        )
                      : _buildPlaceholder(isDark),
                ),
              ),
              const SizedBox(width: 12),
              // 视频信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      item.title ?? item.bvid,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // UP主
                    if (item.ownerName != null && item.ownerName!.isNotEmpty)
                      Text(
                        item.ownerName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    // 浏览时间
                    Text(
                      _formatViewedTime(item.viewedAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
                            : AppColors.lightTextSecondary.withValues(
                                alpha: 0.7,
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              // 删除按钮
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => _showRemoveDialog(context, item),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: '移除',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark
          ? AppColors.darkTextSecondary.withValues(alpha: 0.1)
          : AppColors.lightTextSecondary.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.image_not_supported,
          color: isDark
              ? AppColors.darkTextSecondary.withValues(alpha: 0.3)
              : AppColors.lightTextSecondary.withValues(alpha: 0.3),
          size: 30,
        ),
      ),
    );
  }

  String _formatViewedTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inDays > 365) {
      return '${(diff.inDays / 365).floor()}年前';
    } else if (diff.inDays > 30) {
      return '${(diff.inDays / 30).floor()}个月前';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}天前';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}小时前';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}分钟前';
    } else {
      return '刚刚';
    }
  }

  void _showRemoveDialog(BuildContext context, HistoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除记录'),
        content: Text('确定要移除「${item.title ?? item.bvid}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = context.read<HistoryProvider>();
              final success = await provider.removeHistory(item.bvid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '已移除记录' : '移除失败'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('移除'),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空历史'),
        content: const Text('确定要清空所有浏览历史吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = context.read<HistoryProvider>();
              final success = await provider.clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '已清空历史' : '清空失败'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
