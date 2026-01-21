import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/colors.dart';
import 'share_options_dialog.dart';

/// 视频卡片组件
class VideoCard extends StatefulWidget {
  final LeaderboardItem item;
  final int rank;
  final bool isRank1Custom;
  final VoidCallback? onTap;

  const VideoCard({
    super.key,
    required this.item,
    required this.rank,
    this.isRank1Custom = true,
    this.onTap,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面区域
            AspectRatio(
              aspectRatio: 16 / 10,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 封面图
                  _buildThumbnail(),
                  // 排名徽章
                  Positioned(left: 8, top: 8, child: _buildRankBadge(isDark)),
                  // 分享按钮
                  Positioned(
                    right: 8,
                    top: 8,
                    child: _buildShareButton(context),
                  ),
                  // 底部操作栏
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 收藏按钮
                        _buildFavoriteButton(context),
                        const SizedBox(width: 4),
                        // 抽象指数
                        _buildScoreTag(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // 内容区域
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Text(
                    widget.item.title ?? 'Loading...',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // UP主信息
                  _buildOwnerInfo(theme),
                  const SizedBox(height: 4),
                  // 播放/弹幕数
                  _buildStats(theme),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThumbnail() {
    if (widget.item.picUrl == null || widget.item.picUrl!.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.video_library, size: 48, color: Colors.grey),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: widget.item.picUrl!.replaceFirst('http:', 'https:'),
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[300],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      errorWidget: (context, url, error) => Container(
        color: Colors.grey[300],
        child: const Center(
          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildRankBadge(bool isDark) {
    String rankText;
    Color bgColor;
    Color textColor = Colors.white;

    if (widget.rank == 1 && widget.isRank1Custom) {
      rankText = '何一位';
      bgColor = AppColors.rank1;
      textColor = Colors.black87;
    } else if (widget.rank == 1) {
      rankText = '1';
      bgColor = AppColors.rank1;
      textColor = Colors.black87;
    } else if (widget.rank == 2) {
      rankText = '2';
      bgColor = AppColors.rank2;
      textColor = Colors.black87;
    } else if (widget.rank == 3) {
      rankText = '3';
      bgColor = AppColors.rank3;
    } else {
      rankText = '#${widget.rank}';
      bgColor = isDark ? Colors.black54 : Colors.black38;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        rankText,
        style: TextStyle(
          color: textColor,
          fontSize: widget.rank == 1 && widget.isRank1Custom ? 12 : 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildShareButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ShareOptionsDialog.show(context, widget.item, rank: widget.rank);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.black54,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.share, color: Colors.white, size: 16),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return Consumer<FavoritesProvider>(
      builder: (context, favoritesProvider, _) {
        final isFavorited = favoritesProvider.isFavoritedSync(widget.item.bvid);
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () async {
              await favoritesProvider.toggleFavorite(
                widget.item.bvid,
                title: widget.item.title,
                picUrl: widget.item.picUrl,
                ownerName: widget.item.ownerName,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isFavorited ? '已取消收藏' : '已添加到收藏'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 1),
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? Colors.pinkAccent : Colors.white,
                size: 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('❓', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 4),
          Text(
            '${widget.item.count}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOwnerInfo(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: AppColors.biliBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2),
          ),
          child: const Text(
            'UP',
            style: TextStyle(
              color: AppColors.biliBlue,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            widget.item.ownerName ?? '未知UP',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme) {
    return Row(
      children: [
        _buildStatItem(theme, '▶', _formatCount(widget.item.viewCount)),
        const SizedBox(width: 12),
        _buildStatItem(theme, '💬', _formatCount(widget.item.danmakuCount)),
      ],
    );
  }

  Widget _buildStatItem(ThemeData theme, String icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 2),
        Text(value, style: theme.textTheme.bodySmall?.copyWith(fontSize: 12)),
      ],
    );
  }

  String _formatCount(int? count) {
    if (count == null) return '-';
    if (count >= 100000000) {
      final v = count / 100000000;
      return '${v >= 10 ? v.round() : v.toStringAsFixed(1)}亿';
    }
    if (count >= 10000) {
      final v = count / 10000;
      return '${v >= 10 ? v.round() : v.toStringAsFixed(1)}万';
    }
    return count.toString();
  }
}
