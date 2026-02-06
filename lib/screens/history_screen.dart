import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
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
          late final Widget stateChild;

          // 加载中
          if (provider.isLoading) {
            stateChild = const Center(
              key: ValueKey('history_loading'),
              child: CircularProgressIndicator(),
            );
          } else if (provider.history.isEmpty) {
            // 空状态
            stateChild = KeyedSubtree(
              key: const ValueKey('history_empty'),
              child: _buildEmptyState(isDark),
            );
          } else {
            // 历史记录列表（按日期分组）
            final grouped = provider.getGroupedByDate();
            stateChild = KeyedSubtree(
              key: ValueKey('history_content_${provider.history.length}_${provider.hasActiveFilters}'),
              child: RefreshIndicator(
                onRefresh: () => provider.loadHistory(),
                child: ResponsivePageContainer(
                  maxWidth: 1680,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final contentWidth = constraints.maxWidth;
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        itemCount: grouped.length,
                        itemBuilder: (context, index) {
                          final dateKey = grouped.keys.elementAt(index);
                          final items = grouped[dateKey]!;
                          return _buildDateGroup(
                            context,
                            dateKey,
                            items,
                            isDark,
                            contentWidth,
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            );
          }

          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: stateChild,
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
            '你看过的视频会显示在这里',
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
    double contentWidth,
  ) {
    final useGrid = contentWidth >= ResponsiveBreakpoints.desktop;
    final spacing = useGrid ? 16.0 : 12.0;
    final crossAxisCount = ResponsiveBreakpoints.adaptiveColumnCount(
      contentWidth,
      minTileWidth: 380,
      minCount: 2,
      maxCount: 4,
    );
    final cardWidth =
        (contentWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;

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
        if (useGrid)
          Wrap(
            spacing: spacing,
            runSpacing: 12,
            children: items
                .map(
                  (item) => SizedBox(
                    width: cardWidth,
                    child: _buildHistoryCard(
                      context,
                      item,
                      isDark,
                      isGridMode: true,
                    ),
                  ),
                )
                .toList(),
          )
        else
          ...items.map(
            (item) => _buildHistoryCard(
              context,
              item,
              isDark,
              isGridMode: false,
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    HistoryItem item,
    bool isDark,
    {
      required bool isGridMode,
    }
  ) {
    final thumbWidth = isGridMode ? 136.0 : 120.0;
    final thumbHeight = thumbWidth * 0.625;
    final cardPadding = isGridMode
        ? const EdgeInsets.symmetric(horizontal: 14, vertical: 13)
        : const EdgeInsets.all(12);
    final secondaryColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final tertiaryColor = isDark
        ? AppColors.darkTextSecondary.withValues(alpha: 0.7)
        : AppColors.lightTextSecondary.withValues(alpha: 0.7);

    return RepaintBoundary(
      child: WebHoverLift(
        child: Card(
          margin: isGridMode ? EdgeInsets.zero : const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => VideoScreen(bvid: item.bvid)),
              );
            },
            child: Padding(
              padding: cardPadding,
              child: Row(
                children: [
                  // 封面图
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: SizedBox(
                      width: thumbWidth,
                      height: thumbHeight,
                      child: item.picUrl != null && item.picUrl!.isNotEmpty
                          ? BiliNetworkImage(
                              imageUrl: item.picUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, error) =>
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
                          style: TextStyle(
                            fontSize: isGridMode ? 14.5 : 14,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                        ),
                        SizedBox(height: isGridMode ? 6 : 4),
                        // UP主
                        if (item.ownerName != null && item.ownerName!.isNotEmpty)
                          Text(
                            item.ownerName!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: isGridMode ? 12.5 : 12,
                              color: secondaryColor,
                            ),
                          ),
                        if (item.ownerName != null && item.ownerName!.isNotEmpty)
                          const SizedBox(height: 2),
                        // 浏览时间
                        Text(
                          _formatViewedTime(item.viewedAt),
                          style: TextStyle(
                            fontSize: isGridMode ? 11.5 : 11,
                            color: tertiaryColor,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 删除按钮
                  IconButton(
                    icon: Icon(Icons.close, size: isGridMode ? 18 : 20),
                    onPressed: () => _showRemoveDialog(context, item),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: '移除',
                  ),
                ],
              ),
            ),
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
                if (success) {
                  StatusFeedback.success(context, '已移除记录');
                } else {
                  StatusFeedback.error(context, '移除记录失败，请重试');
                }
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
                if (success) {
                  StatusFeedback.success(context, '已清空历史');
                } else {
                  StatusFeedback.error(context, '清空历史失败，请重试');
                }
              }
            },
            child: const Text('清空', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
