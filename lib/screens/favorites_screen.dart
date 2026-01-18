import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/colors.dart';
import 'video_screen.dart';

/// 收藏页面
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    // 加载收藏列表
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FavoritesProvider>().loadFavorites();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的收藏'),
        actions: [
          Consumer<FavoritesProvider>(
            builder: (context, provider, _) {
              if (provider.favorites.isEmpty) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.delete_sweep),
                onPressed: () => _showClearDialog(context),
                tooltip: '清空收藏',
              );
            },
          ),
        ],
      ),
      body: Consumer<FavoritesProvider>(
        builder: (context, provider, _) {
          // 加载中
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // 空状态
          if (provider.favorites.isEmpty) {
            return _buildEmptyState(isDark);
          }

          // 收藏列表
          return RefreshIndicator(
            onRefresh: () => provider.loadFavorites(),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: provider.favorites.length,
              itemBuilder: (context, index) {
                final item = provider.favorites[index];
                return _buildFavoriteCard(context, item, isDark);
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
            Icons.favorite_border,
            size: 80,
            color: isDark
                ? AppColors.darkTextSecondary.withValues(alpha: 0.5)
                : AppColors.lightTextSecondary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            '暂无收藏',
            style: TextStyle(
              fontSize: 18,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '快去收藏喜欢的视频吧',
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

  Widget _buildFavoriteCard(
    BuildContext context,
    FavoriteItem item,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => VideoScreen(bvid: item.bvid)));
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面图
            AspectRatio(
              aspectRatio: 16 / 10,
              child: item.picUrl != null && item.picUrl!.isNotEmpty
                  ? Image.network(
                      item.picUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildPlaceholder(isDark),
                    )
                  : _buildPlaceholder(isDark),
            ),
            // 视频信息
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 标题
                    Text(
                      item.title ?? item.bvid,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // UP主
                    if (item.ownerName != null && item.ownerName!.isNotEmpty)
                      Text(
                        item.ownerName!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.lightTextSecondary,
                        ),
                      ),
                    // 收藏时间
                    Text(
                      _formatSavedTime(item.savedAt),
                      style: TextStyle(
                        fontSize: 10,
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
            ),
            // 操作按钮
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () => _showRemoveDialog(context, item),
                    icon: const Icon(Icons.delete, size: 16),
                    label: const Text('移除', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                    ),
                  ),
                ),
              ],
            ),
          ],
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
          size: 40,
        ),
      ),
    );
  }

  String _formatSavedTime(DateTime time) {
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

  void _showRemoveDialog(BuildContext context, FavoriteItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除收藏'),
        content: Text('确定要移除「${item.title ?? item.bvid}」吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = context.read<FavoritesProvider>();
              final success = await provider.removeFavorite(item.bvid);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '已移除收藏' : '移除失败'),
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
        title: const Text('清空收藏'),
        content: const Text('确定要清空所有收藏吗？此操作无法撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              final provider = context.read<FavoritesProvider>();
              final success = await provider.clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success ? '已清空收藏' : '清空失败'),
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
