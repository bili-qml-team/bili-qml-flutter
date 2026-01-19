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

/// 主题模式 (App 自定义枚举已移除，直接使用 Flutter 的 ThemeMode)
