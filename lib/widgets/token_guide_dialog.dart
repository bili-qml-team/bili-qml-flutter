import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../theme/colors.dart';

enum TokenGuideReason { missingToken, expiredToken }

class TokenGuideDialog extends StatefulWidget {
  final TokenGuideReason reason;
  final VoidCallback? onOpenSettings;

  const TokenGuideDialog({
    super.key,
    this.reason = TokenGuideReason.missingToken,
    this.onOpenSettings,
  });

  @override
  State<TokenGuideDialog> createState() => _TokenGuideDialogState();
}

class _TokenGuideDialogState extends State<TokenGuideDialog> {
  bool _doNotShowAgain = false;

  Future<void> _onDismiss() async {
    final storageService = context.read<StorageService>();
    if (_doNotShowAgain) {
      await storageService.setWebTokenGuideDismissed(true);
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isExpired = widget.reason == TokenGuideReason.expiredToken;
    final cardColor =
        isDark ? AppColors.darkCardBackground : AppColors.lightCardBackground;
    final primaryText =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryText =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final steps = isExpired
        ? const [
            '1. 去 B 站任意视频页',
            '2. 打开插件设置下滑 → 获取 / 续期',
            '3. 回到 App 在「设置」中更新 Token',
          ]
        : const [
            '1. 去 B 站任意视频页',
            '2. 打开插件设置下滑 → 获取 / 续期',
            '3. 验证成功后重新点击查看web页面按钮跳转回来后即可投票',
          ];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.12),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isExpired ? '投票 Token 已失效' : '还差一步即可投票',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryText,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isExpired
                  ? '当前 Token 已失效，需要重新获取后才能继续投票。'
                  : '当前未绑定 Token，仅能查看榜单。',
              style: TextStyle(
                fontSize: 16,
                color: secondaryText,
              ),
            ),
            const SizedBox(height: 16),
            ...steps
                .map((step) => Column(
                      children: [
                        _buildStep(context, step),
                        const SizedBox(height: 8),
                      ],
                    ))
                .toList()
              ..removeLast(),
            const SizedBox(height: 24),
            Row(
              children: [
                if (!isExpired) ...[
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _doNotShowAgain,
                      onChanged: (value) {
                        setState(() {
                          _doNotShowAgain = value ?? false;
                        });
                      },
                      activeColor: AppColors.biliBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _doNotShowAgain = !_doNotShowAgain;
                      });
                    },
                    child: Text(
                      '不再提示',
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryText,
                      ),
                    ),
                  ),
                ],
                const Spacer(),
                TextButton(
                  onPressed: _onDismiss,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    '知道了',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.biliBlue,
                    ),
                  ),
                ),
                if (widget.onOpenSettings != null) ...[
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onOpenSettings?.call();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.biliBlue,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      '去设置',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6, right: 10),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.biliBlue,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 15,
              color: textColor,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
