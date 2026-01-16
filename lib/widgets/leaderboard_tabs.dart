import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../theme/colors.dart';

/// 排行榜时间范围选项卡
class LeaderboardTabs extends StatelessWidget {
  final LeaderboardRange currentRange;
  final ValueChanged<LeaderboardRange> onRangeChanged;
  final VoidCallback? onSearchPressed;

  const LeaderboardTabs({
    super.key,
    required this.currentRange,
    required this.onRangeChanged,
    this.onSearchPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ...LeaderboardRange.values.map((range) {
              final isSelected = range == currentRange;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _TabButton(
                  label: range.label,
                  isSelected: isSelected,
                  onTap: () => onRangeChanged(range),
                ),
              );
            }),
            if (onSearchPressed != null) ...[
              const SizedBox(width: 8),
              _TabButton(
                label: '查找',
                isSelected: false,
                onTap: onSearchPressed!,
                icon: Icons.search,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.biliBlue
                : (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 16,
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : (isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.lightTextSecondary),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
