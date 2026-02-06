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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1200;
        final verticalPadding = isDesktop ? 10.0 : 8.0;
        final horizontalPadding = isDesktop ? 20.0 : 16.0;
        final tabGap = isDesktop ? 6.0 : 4.0;

        return Container(
          padding: EdgeInsets.symmetric(vertical: verticalPadding),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...LeaderboardRange.values.map((range) {
                  final isSelected = range == currentRange;
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: tabGap / 2),
                    child: _TabButton(
                      label: range.label,
                      isSelected: isSelected,
                      isDesktop: isDesktop,
                      onTap: () => onRangeChanged(range),
                    ),
                  );
                }),
                if (onSearchPressed != null) ...[
                  SizedBox(width: isDesktop ? 10 : 8),
                  _TabButton(
                    label: '筛选',
                    isSelected: false,
                    isDesktop: isDesktop,
                    onTap: onSearchPressed!,
                    icon: Icons.filter_list,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isDesktop;
  final VoidCallback onTap;
  final IconData? icon;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.isDesktop,
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
        borderRadius: BorderRadius.circular(isDesktop ? 22 : 20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isDesktop ? 18 : 16,
            vertical: isDesktop ? 10 : 8,
          ),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.biliBlue
                : (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05)),
            borderRadius: BorderRadius.circular(isDesktop ? 22 : 20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: isDesktop ? 17 : 16,
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
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: isDesktop ? 14.5 : 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
