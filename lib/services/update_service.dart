import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

/// GitHub Release 信息模型
class ReleaseInfo {
  /// 版本标签，如 "v1.0.1"
  final String tagName;

  /// Release 名称
  final String name;

  /// Release 描述（更新日志）
  final String body;

  /// Release 页面 URL
  final String htmlUrl;

  /// 发布时间
  final DateTime publishedAt;

  ReleaseInfo({
    required this.tagName,
    required this.name,
    required this.body,
    required this.htmlUrl,
    required this.publishedAt,
  });

  /// 提取纯版本号（去掉 'v' 前缀）
  String get version => tagName.replaceFirst(RegExp(r'^v'), '');

  factory ReleaseInfo.fromJson(Map<String, dynamic> json) {
    return ReleaseInfo(
      tagName: json['tag_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      body: json['body'] as String? ?? '',
      htmlUrl: json['html_url'] as String? ?? '',
      publishedAt:
          DateTime.tryParse(json['published_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// 更新检查服务
class UpdateService {
  /// 检查更新
  ///
  /// 返回 [ReleaseInfo] 如果有新版本可用，否则返回 null
  Future<ReleaseInfo?> checkForUpdate() async {
    // Web 端跳过更新检查
    if (kIsWeb) {
      return null;
    }

    try {
      final uri = Uri.parse(GitHubConfig.latestReleaseApi);
      final response = await http
          .get(
            uri,
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'bili-qml-flutter-app',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        debugPrint('GitHub API 请求失败: ${response.statusCode}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final releaseInfo = ReleaseInfo.fromJson(json);

      // 比较版本号
      if (isNewer(releaseInfo.version, AppVersion.current)) {
        debugPrint('发现新版本: ${releaseInfo.version} (当前: ${AppVersion.current})');
        return releaseInfo;
      }

      debugPrint('当前已是最新版本: ${AppVersion.current}');
      return null;
    } catch (e) {
      // 静默处理错误，不影响用户正常使用
      debugPrint('检查更新失败: $e');
      return null;
    }
  }

  /// 比较版本号，判断远程版本是否比当前版本更新
  ///
  /// 使用语义化版本比较 (major.minor.patch)
  bool isNewer(String remoteVersion, String currentVersion) {
    try {
      final remoteParts = _parseVersion(remoteVersion);
      final currentParts = _parseVersion(currentVersion);

      // 比较 major
      if (remoteParts[0] > currentParts[0]) return true;
      if (remoteParts[0] < currentParts[0]) return false;

      // 比较 minor
      if (remoteParts[1] > currentParts[1]) return true;
      if (remoteParts[1] < currentParts[1]) return false;

      // 比较 patch
      if (remoteParts[2] > currentParts[2]) return true;

      return false;
    } catch (e) {
      debugPrint('版本号解析失败: $e');
      return false;
    }
  }

  /// 解析版本号为 [major, minor, patch] 列表
  List<int> _parseVersion(String version) {
    // 移除可能的 'v' 前缀
    final cleanVersion = version.replaceFirst(RegExp(r'^v'), '');

    // 只取主版本号部分（忽略 -beta, -rc 等后缀）
    final mainVersion = cleanVersion.split('-').first;

    final parts = mainVersion.split('.');

    return [
      int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
      int.tryParse(parts.length > 2 ? parts[2] : '0') ?? 0,
    ];
  }
}
