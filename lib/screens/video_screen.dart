import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

class _VideoScreenState extends State<VideoScreen> {
  bool _isVoting = false;
  UserStatus? _status;
  VideoInfo? _videoInfo;

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
            _showSnackBar(isVoting ? '投票成功 ❓' : '已取消投票');
          } else {
            _showSnackBar('操作失败: ${retryResponse.error}');
          }
        }
      } else if (response.success) {
        await _reloadStatus();
        _showSnackBar(isVoting ? '投票成功 ❓' : '已取消投票');
      } else {
        _showSnackBar('操作失败: ${response.error}');
      }
    } catch (e) {
      _showSnackBar('网络错误: $e');
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

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(_videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                    _showSnackBar(isFavorited ? '已取消收藏' : '已添加到收藏');
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
    );
  }

  Widget _buildBody() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_videoInfo != null)
              Container(
                constraints: const BoxConstraints(maxWidth: 480),
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
              )
            else
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.biliBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text('📺', style: TextStyle(fontSize: 40)),
                ),
              ),
            const SizedBox(height: 24),
            Text(
              _videoInfo?.title ?? widget.title ?? 'BV${widget.bvid}',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
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
              ),
              const SizedBox(height: 8),
              Text(
                _status!.active ? '您已投票' : '您还未投票',
                style: TextStyle(
                  color: _status!.active ? AppColors.success : null,
                ),
              ),
              const SizedBox(height: 24),
            ] else
              const Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: CircularProgressIndicator(),
              ),
            ElevatedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_browser),
              label: const Text('在浏览器中观看'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
