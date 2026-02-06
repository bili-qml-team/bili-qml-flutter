import 'package:flutter/material.dart';

import '../theme/colors.dart';

enum StatusTone { success, warning, error, info }

class StatusFeedback {
  static void show(
    BuildContext context,
    String message, {
    StatusTone tone = StatusTone.info,
    Duration duration = const Duration(seconds: 2),
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final icon = switch (tone) {
      StatusTone.success => Icons.check_circle,
      StatusTone.warning => Icons.warning_amber_rounded,
      StatusTone.error => Icons.error,
      StatusTone.info => Icons.info,
    };

    final backgroundColor = switch (tone) {
      StatusTone.success => isDark ? const Color(0xFF1F3A2A) : const Color(0xFF1C7C41),
      StatusTone.warning => isDark ? const Color(0xFF4A3A1E) : const Color(0xFF9A6500),
      StatusTone.error => isDark ? const Color(0xFF4A1F24) : const Color(0xFFB3261E),
      StatusTone.info =>
        theme.snackBarTheme.backgroundColor ??
            (isDark ? AppColors.darkCardBackgroundElevated : const Color(0xFF1F2329)),
    };

    final foregroundColor = switch (tone) {
      StatusTone.info => isDark ? AppColors.darkTextPrimary : Colors.white,
      _ => Colors.white,
    };

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: backgroundColor,
        duration: duration,
        content: Row(
          children: [
            Icon(icon, color: foregroundColor, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void success(BuildContext context, String message) =>
      show(context, message, tone: StatusTone.success);

  static void warning(BuildContext context, String message) =>
      show(context, message, tone: StatusTone.warning);

  static void error(BuildContext context, String message) =>
      show(context, message, tone: StatusTone.error);

  static void info(BuildContext context, String message) =>
      show(context, message, tone: StatusTone.info);
}
