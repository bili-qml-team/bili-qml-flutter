import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/providers.dart';
import '../theme/colors.dart';
import 'share_options_dialog.dart';
import 'bili_network_image.dart';
import 'status_feedback.dart';

/// 视频卡片组件
class VideoCard extends StatefulWidget {
  final LeaderboardItem item;
  final int rank;
  final bool isRank1Custom;
  final VoidCallback? onTap;
  final bool isHighPriorityImage;

  const VideoCard({
    super.key,
    required this.item,
    required this.rank,
    this.isRank1Custom = true,
    this.onTap,
    this.isHighPriorityImage = false,
  });

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  bool _isHovering = false;

  BoxShadow _softShadow({
    required double blur,
    required Offset offset,
    required double alpha,
  }) {
    final scale = kIsWeb ? 0.7 : 1.0;
    return BoxShadow(
      color: Colors.black.withValues(alpha: alpha * scale),
      blurRadius: blur * scale,
      offset: Offset(offset.dx * scale, offset.dy * scale),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final isWideCard = cardWidth >= 280;
        final isCompactCard = cardWidth <= 210;
        final contentPadding = isWideCard
            ? 14.0
            : isCompactCard
                ? 10.0
                : 12.0;
        final titleFontSize = isWideCard
            ? 15.0
            : isCompactCard
                ? 13.0
                : 14.0;

        final card = Card(
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
                      _buildThumbnail(isDark),
                      // 排名徽章
                      Positioned(
                        left: isWideCard ? 10 : 8,
                        top: isWideCard ? 10 : 8,
                        child: _buildRankBadge(isDark, isWideCard),
                      ),
                      // 分享按钮
                      Positioned(
                        right: isWideCard ? 10 : 8,
                        top: isWideCard ? 10 : 8,
                        child: _buildShareButton(context, isWideCard, isDark),
                      ),
                      // 底部操作栏
                      Positioned(
                        right: isWideCard ? 10 : 8,
                        bottom: isWideCard ? 10 : 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 收藏按钮
                            _buildFavoriteButton(context, isWideCard, isDark),
                            const SizedBox(width: 4),
                            // 抽象指数
                            _buildScoreTag(isWideCard, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // 内容区域
                Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      Text(
                        widget.item.title ?? 'Loading...',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          fontSize: titleFontSize,
                        ),
                      ),
                      SizedBox(height: isCompactCard ? 6 : 8),
                      // UP主信息
                      _buildOwnerInfo(theme, isWideCard),
                      SizedBox(height: isCompactCard ? 3 : 4),
                      // 播放/弹幕数
                      _buildStats(theme, isWideCard),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

        if (!kIsWeb || widget.onTap == null) {
          return card;
        }

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            if (_isHovering) return;
            setState(() => _isHovering = true);
          },
          onExit: (_) {
            if (!_isHovering) return;
            setState(() => _isHovering = false);
          },
          child: AnimatedScale(
            scale: _isHovering ? 1.015 : 1,
            duration: const Duration(milliseconds: 130),
            curve: Curves.easeOutCubic,
            child: AnimatedSlide(
              offset: _isHovering ? const Offset(0, -0.01) : Offset.zero,
              duration: const Duration(milliseconds: 130),
              curve: Curves.easeOutCubic,
              child: card,
            ),
          ),
        );
      },
    );
  }

  Widget _buildThumbnail(bool isDark) {
    Widget content;
    final placeholderColor = isDark
        ? AppColors.darkCardBackgroundElevated
        : Colors.grey[300];
    final placeholderIconColor = isDark
        ? AppColors.darkTextTertiary
        : Colors.grey;

    if (widget.item.picUrl == null || widget.item.picUrl!.isEmpty) {
      content = Container(
        color: placeholderColor,
        child: Center(
          child: Icon(
            Icons.video_library,
            size: 48,
            color: placeholderIconColor,
          ),
        ),
      );
    } else {
      content = BiliNetworkImage(
        imageUrl: widget.item.picUrl!,
        fit: BoxFit.cover,
        isHighPriority: widget.isHighPriorityImage,
        placeholder: (context) => Container(
          color: placeholderColor,
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, error) => Container(
          color: placeholderColor,
          child: Center(
            child: Icon(
              Icons.broken_image,
              size: 48,
              color: placeholderIconColor,
            ),
          ),
        ),
      );
    }

    if (widget.onTap == null) {
      return content;
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        content,
        Positioned.fill(
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(onTap: widget.onTap),
          ),
        ),
      ],
    );
  }

  Widget _buildRankBadge(bool isDark, bool isWideCard) {
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
      bgColor = isDark ? AppColors.overlayOnImageDark : Colors.black38;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWideCard ? 9 : 8,
        vertical: isWideCard ? 5 : 4,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(isWideCard ? 5 : 4),
        boxShadow: [
          _softShadow(
            blur: 4,
            offset: const Offset(0, 2),
            alpha: 0.2,
          ),
        ],
      ),
      child: Text(
        rankText,
        style: TextStyle(
          color: textColor,
          fontSize: widget.rank == 1 && widget.isRank1Custom
              ? (isWideCard ? 13 : 12)
              : (isWideCard ? 15 : 14),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildShareButton(BuildContext context, bool isWideCard, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ShareOptionsDialog.show(context, widget.item, rank: widget.rank);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: isWideCard ? 34 : 32,
          height: isWideCard ? 34 : 32,
          decoration: BoxDecoration(
            color: _overlayColor(isDark),
            shape: BoxShape.circle,
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.2),
            ),
            boxShadow: [
              _softShadow(
                blur: 4,
                offset: const Offset(0, 2),
                alpha: 0.2,
              ),
            ],
          ),
          child: Icon(
            Icons.share,
            color: Colors.white,
            size: isWideCard ? 18 : 16,
          ),
        ),
      ),
    );
  }

  Widget _buildFavoriteButton(
    BuildContext context,
    bool isWideCard,
    bool isDark,
  ) {
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
                if (isFavorited) {
                  StatusFeedback.info(context, '已取消收藏');
                } else {
                  StatusFeedback.success(context, '已添加到收藏');
                }
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: isWideCard ? 30 : 28,
              height: isWideCard ? 30 : 28,
              decoration: BoxDecoration(
                color: _overlayColor(isDark),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.white.withValues(alpha: 0.2),
                ),
              ),
              child: Icon(
                isFavorited ? Icons.favorite : Icons.favorite_border,
                color: isFavorited ? Colors.pinkAccent : Colors.white,
                size: isWideCard ? 17 : 16,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreTag(bool isWideCard, bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isWideCard ? 9 : 8,
        vertical: isWideCard ? 5 : 4,
      ),
      decoration: BoxDecoration(
        color: _overlayColor(isDark),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('❓', style: TextStyle(fontSize: isWideCard ? 15 : 14)),
          const SizedBox(width: 4),
          Text(
            '${widget.item.count}',
            style: TextStyle(
              color: Colors.white,
              fontSize: isWideCard ? 15 : 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _overlayColor(bool isDark) {
    return isDark ? AppColors.overlayOnImageDark : AppColors.overlayOnImageLight;
  }

  Widget _buildOwnerInfo(ThemeData theme, bool isWideCard) {
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
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: isWideCard ? 12 : 11.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats(ThemeData theme, bool isWideCard) {
    return Row(
      children: [
        _buildStatItem(
          theme,
          '▶',
          _formatCount(widget.item.viewCount),
          isWideCard,
        ),
        SizedBox(width: isWideCard ? 14 : 12),
        _buildStatItem(
          theme,
          '💬',
          _formatCount(widget.item.danmakuCount),
          isWideCard,
        ),
      ],
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String icon,
    String value,
    bool isWideCard,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: TextStyle(fontSize: isWideCard ? 12.5 : 12)),
        const SizedBox(width: 2),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: isWideCard ? 12.5 : 12,
          ),
        ),
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
