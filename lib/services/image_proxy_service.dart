import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'api_service.dart';

/// 图片代理服务
/// 用于在 Web 端将 B站图片 URL 转换为服务器代理 URL
class ImageProxyService {
  /// 将 B站图片 URL 转换为代理 URL（仅 Web 端）
  ///
  /// 支持的 URL 格式：
  /// - https://i0.hdslb.com/bfs/archive/xxx.jpg
  /// - http://i0.hdslb.com/bfs/archive/xxx.jpg
  ///
  /// 转换后格式：
  /// - {apiBase}/bfs/archive/xxx.jpg
  static String convertImageUrl(String? imageUrl, String apiBase) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // 非 Web 端不需要代理
    if (!kIsWeb) {
      return imageUrl.replaceFirst('http:', 'https:');
    }

    // 检查是否是 B站 archive 图片 URL
    final archivePattern = RegExp(
      r'^https?://i\d\.hdslb\.com/bfs/archive/(.+)$',
      caseSensitive: false,
    );

    final match = archivePattern.firstMatch(imageUrl);
    if (match != null) {
      final path = match.group(1)!;
      // 确保 apiBase 末尾没有斜杠
      final baseUrl = apiBase.replaceAll(RegExp(r'/+$'), '');
      // 移除 /api 后缀（如果存在），因为代理路由是 /bfs/archive 或 /api/bfs/archive
      final cleanBase = baseUrl.replaceAll(RegExp(r'/api$'), '');
      return '$cleanBase/bfs/archive/$path';
    }

    // 其他 URL 直接返回（确保 https）
    return imageUrl.replaceFirst('http:', 'https:');
  }

  /// 从 BuildContext 获取 API base 并转换图片 URL
  static String getProxiedImageUrl(BuildContext context, String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return '';
    }

    // 非 Web 端直接返回
    if (!kIsWeb) {
      return imageUrl.replaceFirst('http:', 'https:');
    }

    try {
      final apiService = context.read<ApiService>();
      return convertImageUrl(imageUrl, apiService.apiBase);
    } catch (e) {
      // 如果无法获取 ApiService，直接返回原 URL
      return imageUrl.replaceFirst('http:', 'https:');
    }
  }
}
