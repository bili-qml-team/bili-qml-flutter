import 'package:flutter/material.dart';

/// 响应式断点与布局工具
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double wideDesktop = 1600;

  static bool isDesktopWidth(double width) => width >= desktop;

  static double contentMaxWidth(double width) {
    if (width >= 1900) return 1680;
    if (width >= wideDesktop) return 1480;
    if (width >= desktop) return 1280;
    return width;
  }

  static EdgeInsets horizontalPadding(double width) {
    if (width >= wideDesktop) {
      return const EdgeInsets.symmetric(horizontal: 24);
    }
    if (width >= desktop) {
      return const EdgeInsets.symmetric(horizontal: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  static int adaptiveColumnCount(
    double width, {
    required double minTileWidth,
    int minCount = 1,
    int maxCount = 8,
  }) {
    final count = (width / minTileWidth).floor();
    return count.clamp(minCount, maxCount);
  }
}

/// 居中内容容器：小屏保持原有体验，宽屏限制最大内容宽度
class ResponsivePageContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;

  const ResponsivePageContainer({
    super.key,
    required this.child,
    this.maxWidth,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final resolvedMaxWidth =
            maxWidth ?? ResponsiveBreakpoints.contentMaxWidth(width);

        return Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: resolvedMaxWidth),
            child: Padding(
              padding: ResponsiveBreakpoints.horizontalPadding(width),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
