import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../services/services.dart';
import '../widgets/widgets.dart';
import '../theme/colors.dart';
import 'settings_screen.dart';

/// 视频详情页
class VideoScreen extends StatefulWidget {
  final String bvid;
  final String? title;

  const VideoScreen({super.key, required this.bvid, this.title});

  @override
  State<VideoScreen> createState() => _VideoScreenState();
}

enum _CopyTarget { bvid, ownerUid }

class _VideoScreenState extends State<VideoScreen> {
  bool _isVoting = false;
  UserStatus? _status;
  VideoInfo? _videoInfo;
  bool _copiedBvid = false;
  bool _copiedOwnerUid = false;
  int _copiedBvidVersion = 0;
  int _copiedOwnerUidVersion = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  String get _videoUrl => 'https://www.bilibili.com/video/${widget.bvid}';

  /// 记录浏览历史
  Future<void> _recordHistory() async {
    try {
      final historyProvider = context.read<HistoryProvider>();
      await historyProvider.addHistory(
        widget.bvid,
        title: _videoInfo?.title ?? widget.title,
        picUrl: _videoInfo?.pic,
        ownerName: _videoInfo?.ownerName,
      );
    } catch (e) {
      debugPrint('记录浏览历史失败: $e');
    }
  }

  Future<void> _loadData() async {
    try {
      final apiService = context.read<ApiService>();
      final settingsProvider = context.read<SettingsProvider>();
      final userId = settingsProvider.userId;

      // Load status
      apiService
          .getStatus(widget.bvid, userId)
          .then((status) {
            if (mounted) {
              setState(() => _status = status);
            }
          })
          .catchError((e) {
            debugPrint('Failed to load status: $e');
          });

      // Load video info
      apiService
          .getBilibiliVideoInfo(widget.bvid)
          .then((info) {
            if (mounted && info != null) {
              setState(() => _videoInfo = info);
              // 在获取到视频信息后记录浏览历史
              _recordHistory();
            }
          })
          .catchError((e) {
            debugPrint('Failed to load video info: $e');
          });
    } catch (e) {
      debugPrint('Error starting load: $e');
    }
  }

  Future<void> _handleVote() async {
    final settingsProvider = context.read<SettingsProvider>();
    final userId = settingsProvider.userId;
    final voteToken = settingsProvider.voteToken;

    final missingUserId = userId == null || userId.isEmpty;
    final missingToken = voteToken == null || voteToken.isEmpty;

    if (missingUserId || missingToken) {
      _showVotePrerequisiteDialog(
        missingUserId: missingUserId,
        missingToken: missingToken,
      );
      return;
    }

    setState(() => _isVoting = true);

    try {
      final apiService = context.read<ApiService>();
      final isVoting = _status?.active != true;

      final response = isVoting
          ? await apiService.vote(widget.bvid, userId)
          : await apiService.unvote(widget.bvid, userId);

      if (!mounted) return;

      if (_isTokenInvalid(response)) {
        _showTokenExpiredDialog();
        return;
      }

      if (response.requiresCaptcha) {
        // 显示验证对话框
        final altchaService = AltchaService(apiService);
        final solution = await AltchaDialog.show(context, altchaService);

        if (solution != null && mounted) {
          // 使用验证码重试
          final retryResponse = isVoting
              ? await apiService.vote(widget.bvid, userId, altcha: solution)
              : await apiService.unvote(widget.bvid, userId, altcha: solution);

          if (_isTokenInvalid(retryResponse)) {
            _showTokenExpiredDialog();
            return;
          }

          if (retryResponse.success) {
            await _reloadStatus();
            _showSnackBar(
              isVoting ? '投票成功' : '已取消投票',
              tone: StatusTone.success,
            );
          } else {
            _showSnackBar(
              "操作失败：${retryResponse.error ?? '请稍后重试'}",
              tone: StatusTone.error,
            );
          }
        }
      } else if (response.success) {
        await _reloadStatus();
        _showSnackBar(
          isVoting ? '投票成功' : '已取消投票',
          tone: StatusTone.success,
        );
      } else {
        _showSnackBar(
          "操作失败：${response.error ?? '请稍后重试'}",
          tone: StatusTone.error,
        );
      }
    } catch (e) {
      _showSnackBar('网络异常，请稍后重试', tone: StatusTone.error);
    } finally {
      if (mounted) {
        setState(() => _isVoting = false);
      }
    }
  }

  Future<void> _reloadStatus() async {
    try {
      final apiService = context.read<ApiService>();
      final settingsProvider = context.read<SettingsProvider>();
      final userId = settingsProvider.userId;
      final status = await apiService.getStatus(widget.bvid, userId);
      if (mounted) {
        setState(() {
          _status = status;
        });
      }
    } catch (e) {
      debugPrint('Failed to reload status: $e');
    }
  }

  bool _isTokenInvalid(ApiResponse response) {
    if (response.statusCode == 401) {
      return true;
    }
    final error = response.error?.toLowerCase();
    return error != null && error.contains('unauthorized');
  }

  void _showTokenExpiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => TokenGuideDialog(
        reason: TokenGuideReason.expiredToken,
        onOpenSettings: _openSettings,
      ),
    );
  }

  void _showVotePrerequisiteDialog({
    required bool missingUserId,
    required bool missingToken,
  }) {
    final missingLabel =
        missingUserId && missingToken
            ? 'B站 UID 和投票 Token'
            : missingUserId
            ? 'B站 UID'
            : '投票 Token';

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('无法投票'),
        content: Text('当前未设置 $missingLabel。\n\n请前往「设置」填写后再投票。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('知道了'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _openSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    if (!mounted) return;
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const SettingsScreen()));
  }

  void _showSnackBar(String message, {StatusTone tone = StatusTone.info}) {
    StatusFeedback.show(context, message, tone: tone);
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(_videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isWideScreen = MediaQuery.sizeOf(context).width >= 1080;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title ?? 'BV${widget.bvid}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              if (_videoInfo != null) {
                final item = LeaderboardItem(
                  bvid: widget.bvid,
                  count: _status?.count ?? 0,
                  title: _videoInfo!.title,
                  picUrl: _videoInfo!.pic,
                  ownerName: _videoInfo!.ownerName,
                  viewCount: _videoInfo!.view,
                  danmakuCount: _videoInfo!.danmaku,
                );
                ShareOptionsDialog.show(context, item);
              } else {
                final item = LeaderboardItem(
                  bvid: widget.bvid,
                  count: _status?.count ?? 0,
                  title: widget.title,
                );
                ShareOptionsDialog.show(context, item);
              }
            },
            tooltip: '分享',
          ),
          Consumer<FavoritesProvider>(
            builder: (context, favoritesProvider, _) {
              final isFavorited = favoritesProvider.isFavoritedSync(
                widget.bvid,
              );
              return IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.pinkAccent : null,
                ),
                onPressed: () async {
                  await favoritesProvider.toggleFavorite(
                    widget.bvid,
                    title: _videoInfo?.title ?? widget.title,
                    picUrl: _videoInfo?.pic,
                    ownerName: _videoInfo?.ownerName,
                  );
                  if (mounted) {
                    _showSnackBar(
                      isFavorited ? '已取消收藏' : '已添加到收藏',
                      tone: isFavorited ? StatusTone.info : StatusTone.success,
                    );
                  }
                },
                tooltip: isFavorited ? '取消收藏' : '收藏',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInBrowser,
            tooltip: '在浏览器中打开',
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _status != null
          ? VoteFab(
              count: _status!.count,
              isVoted: _status!.active,
              isLoading: _isVoting,
              onPressed: _handleVote,
            )
          : null,
      floatingActionButtonLocation: isWideScreen
          ? FloatingActionButtonLocation.centerFloat
          : FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildBody() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1080;

        return ResponsivePageContainer(
          maxWidth: isWide ? 1400 : null,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: _buildVideoCover(isWide: true)),
                      const SizedBox(width: 32),
                      Expanded(
                        flex: 6,
                        child: _buildVideoInfo(
                          isWide: true,
                          textAlign: TextAlign.left,
                          crossAxisAlignment: CrossAxisAlignment.start,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      _buildVideoCover(isWide: false),
                      const SizedBox(height: 24),
                      _buildVideoInfo(
                        isWide: false,
                        textAlign: TextAlign.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildVideoCover({required bool isWide}) {
    if (_videoInfo == null) {
      if (!isWide) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.biliBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(child: Text('📺', style: TextStyle(fontSize: 40))),
        );
      }

      return Container(
        constraints: const BoxConstraints(maxWidth: 640),
        decoration: BoxDecoration(
          color: AppColors.biliBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const AspectRatio(
          aspectRatio: 16 / 9,
          child: Center(
            child: SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
        ),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 640),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: BiliNetworkImage(
          imageUrl: _videoInfo!.pic,
          fit: BoxFit.cover,
          errorWidget: (context, error) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, color: Colors.grey),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideoInfo({
    required bool isWide,
    required TextAlign textAlign,
    required CrossAxisAlignment crossAxisAlignment,
  }) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          _videoInfo?.title ?? widget.title ?? 'BV${widget.bvid}',
          style: Theme.of(context).textTheme.titleLarge,
          textAlign: textAlign,
        ),
        const SizedBox(height: 8),
        Text(widget.bvid, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 24),
        if (_status != null) ...[
          Text(
            '❓ 抽象指数: ${_status!.count}',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.biliBlue,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: textAlign,
          ),
          const SizedBox(height: 8),
          Text(
            _status!.active ? '当前状态：已投票' : '当前状态：未投票',
            style: TextStyle(
              color: _status!.active ? AppColors.success : null,
            ),
            textAlign: textAlign,
          ),
          const SizedBox(height: 20),
        ] else
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: isWide
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '正在加载视频状态...',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        _buildDetailsSection(isWide: isWide, textAlign: textAlign),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _openInBrowser,
          icon: const Icon(Icons.open_in_browser),
          label: const Text('在浏览器中观看'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSection({required bool isWide, required TextAlign textAlign}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final info = _videoInfo;

    final section = Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '视频详细信息',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          if (info == null)
            Text(
              '详细信息加载中...',
              style: theme.textTheme.bodySmall,
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: isWide ? 16 : 12,
                  runSpacing: 10,
                  children: [
                    _buildDetailItem('BV号', info.bvid, isWide),
                    _buildDetailItem('UP主', info.ownerName, isWide),
                    _buildDetailItem('UP主UID', info.ownerMid.toString(), isWide),
                    _buildDetailItem('播放', _formatCount(info.view), isWide),
                    _buildDetailItem('弹幕', _formatCount(info.danmaku), isWide),
                    _buildDetailItem('点赞', _formatCount(info.like), isWide),
                    _buildDetailItem('投币', _formatCount(info.coin), isWide),
                    _buildDetailItem('收藏', _formatCount(info.favorite), isWide),
                    _buildDetailItem('分享', _formatCount(info.share), isWide),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ActionChip(
                      avatar: Icon(
                        _copiedBvid ? Icons.check : Icons.copy,
                        size: 16,
                      ),
                      label: Text(_copiedBvid ? 'BV号已复制' : '复制 BV号'),
                      onPressed: () => _copyDetailValue(
                        info.bvid,
                        'BV号',
                        target: _CopyTarget.bvid,
                      ),
                    ),
                    ActionChip(
                      avatar: Icon(
                        _copiedOwnerUid ? Icons.check : Icons.copy,
                        size: 16,
                      ),
                      label: Text(_copiedOwnerUid ? 'UP主UID已复制' : '复制 UP主UID'),
                      onPressed: () => _copyDetailValue(
                        info.ownerMid.toString(),
                        'UP主UID',
                        target: _CopyTarget.ownerUid,
                      ),
                    ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );

    if (textAlign == TextAlign.left) {
      return section;
    }

    return Align(
      alignment: Alignment.center,
      child: section,
    );
  }

  Widget _buildDetailItem(String label, String value, bool isWide) {
    final theme = Theme.of(context);
    final itemWidth = isWide ? 180.0 : 150.0;

    return SizedBox(
      width: itemWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Future<void> _copyDetailValue(
    String value,
    String label, {
    required _CopyTarget target,
  }) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (!mounted) return;
      _showCopiedState(target);
      _showSnackBar('$label已复制', tone: StatusTone.success);
    } catch (_) {
      if (!mounted) return;
      _showSnackBar('复制失败，请重试', tone: StatusTone.error);
    }
  }

  void _showCopiedState(_CopyTarget target) {
    switch (target) {
      case _CopyTarget.bvid:
        final currentVersion = ++_copiedBvidVersion;
        setState(() => _copiedBvid = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted || currentVersion != _copiedBvidVersion) return;
          setState(() => _copiedBvid = false);
        });
        break;
      case _CopyTarget.ownerUid:
        final currentVersion = ++_copiedOwnerUidVersion;
        setState(() => _copiedOwnerUid = true);
        Future.delayed(const Duration(seconds: 2), () {
          if (!mounted || currentVersion != _copiedOwnerUidVersion) return;
          setState(() => _copiedOwnerUid = false);
        });
        break;
    }
  }

  String _formatCount(int count) {
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
