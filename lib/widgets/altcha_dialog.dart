import 'package:flutter/material.dart';
import '../services/services.dart';
import '../theme/colors.dart';

/// Altcha 验证对话框
class AltchaDialog extends StatefulWidget {
  final AltchaService altchaService;

  const AltchaDialog({super.key, required this.altchaService});

  /// 显示对话框并返回验证结果
  static Future<String?> show(BuildContext context, AltchaService service) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AltchaDialog(altchaService: service),
    );
  }

  @override
  State<AltchaDialog> createState() => _AltchaDialogState();
}

class _AltchaDialogState extends State<AltchaDialog> {
  bool _isVerifying = false;
  double _progress = 0;
  String _statusText = '检测到频繁操作，请完成验证';
  String? _error;

  Future<void> _startVerification() async {
    setState(() {
      _isVerifying = true;
      _progress = 0;
      _statusText = '正在获取验证挑战...';
      _error = null;
    });

    try {
      final solution = await widget.altchaService.solveChallenge(
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _progress = progress;
              _statusText = '正在计算验证...';
            });
          }
        },
      );

      if (mounted) {
        setState(() {
          _progress = 1.0;
          _statusText = '验证成功！';
        });

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pop(solution);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _error = '验证失败: ${e.toString()}';
          _statusText = _error!;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.all(24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 图标
          const Text('🤖', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),

          // 标题
          Text(
            '人机验证',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // 状态文本
          Text(
            _statusText,
            textAlign: TextAlign.center,
            style: TextStyle(color: _error != null ? AppColors.error : null),
          ),
          const SizedBox(height: 20),

          // 进度条
          if (_isVerifying) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: const AlwaysStoppedAnimation(AppColors.biliBlue),
              ),
            ),
            const SizedBox(height: 8),
            Text('正在验证中...', style: theme.textTheme.bodySmall),
          ],

          // 按钮区域
          if (!_isVerifying) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 开始验证按钮
                ElevatedButton(
                  onPressed: _startVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.biliBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('开始验证'),
                ),
                const SizedBox(width: 12),
                // 取消按钮
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text('取消'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
