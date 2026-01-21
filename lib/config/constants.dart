/// API 配置常量
class ApiConfig {
  /// 默认 API 服务器地址
  static const String defaultApiBase = 'https://bili-qml.bydfk.com/api';

  /// B站 API 地址
  static const String bilibiliApiBase = 'https://api.bilibili.com';

  /// 本地存储键名

  static const String storageKeyApiEndpoint = 'apiEndpoint';
  static const String storageKeyTheme = 'theme';
  static const String storageKeyRank1Setting = 'rank1Setting';
  static const String storageKeyUserId = 'userId';

  /// 排行榜缓存相关
  static const String storageKeyLeaderboardCache = 'leaderboard_cache';
  static const String storageKeyLeaderboardCacheTime = 'leaderboard_cache_time';
  static const int leaderboardCacheDuration = 2 * 60 * 1000; // 2分钟（毫秒）
}

/// 排行榜时间范围
enum LeaderboardRange {
  realtime('realtime', '实时'),
  daily('daily', '日榜'),
  weekly('weekly', '周榜'),
  monthly('monthly', '月榜');

  final String value;
  final String label;

  const LeaderboardRange(this.value, this.label);
}

/// GitHub 配置
class GitHubConfig {
  /// GitHub 仓库信息
  static const String owner = 'bili-qml-team';
  static const String repo = 'bili-qml-flutter';

  /// GitHub Releases API 地址
  static String get latestReleaseApi =>
      'https://api.github.com/repos/$owner/$repo/releases/latest';

  /// GitHub Releases 页面地址
  static String get releasesPageUrl =>
      'https://github.com/$owner/$repo/releases/latest';

  /// QQ 群链接（备用更新渠道）
  static const String qqGroupUrl = 'https://qm.qq.com/q/Yc8xTHKZqA';
}

/// 应用版本信息
class AppVersion {
  /// 当前应用版本（需要与 pubspec.yaml 保持同步）
  static const String current = '1.1.0';
}
