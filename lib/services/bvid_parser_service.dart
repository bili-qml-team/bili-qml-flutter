import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// BV号解析服务
/// 
/// 负责解析各种格式的BV号输入，包括：
/// - 纯BV号（如：BV1SnrGBQE2U 或 1SnrGBQE2U）
/// - 完整链接（如：https://www.bilibili.com/video/BV1QMrhBkE8r/）
/// - 带参数链接（如：https://www.bilibili.com/video/BV1QMrhBkE8r/?share_source=copy_web）
/// - B站短链接（如：https://b23.tv/sne4c22）
class BvidParserService {
  /// 解析BV号（同步方法，不处理短链接）
  /// 
  /// [input] 用户输入的文本
  /// 返回解析出的BV号，如果无法解析则返回null
  String? parseBvid(String input) {
    if (input.isEmpty) return null;

    // 1. 尝试匹配纯BV号（带或不带"BV"前缀）
    // BV号通常是10-12位字母数字组合
    final bvPattern = RegExp(
      r'^(BV)?([a-zA-Z0-9]{10,12})$',
      caseSensitive: false,
    );
    final directMatch = bvPattern.firstMatch(input);
    if (directMatch != null) {
      final bv = directMatch.group(2);
      return bv != null ? 'BV$bv' : null;
    }

    // 2. 尝试从URL中提取BV号
    // 支持格式：
    // - https://www.bilibili.com/video/BV1QMrhBkE8r/
    // - https://www.bilibili.com/video/BV1QMrhBkE8r/?share_source=copy_web
    // - https://www.bilibili.com/video/BV1qtrfBYEEN?t=1
    final urlPattern = RegExp(
      r'bilibili\.com/video/(BV[a-zA-Z0-9]+)',
      caseSensitive: false,
    );
    final urlMatch = urlPattern.firstMatch(input);
    if (urlMatch != null) {
      return urlMatch.group(1);
    }

    // 3. 尝试从任意文本中提取BV号
    // 匹配BV开头后跟字母数字，直到遇到非字母数字字符
    final anyBvPattern = RegExp(
      r'(BV[a-zA-Z0-9]+)',
      caseSensitive: false,
    );
    final anyMatch = anyBvPattern.firstMatch(input);
    if (anyMatch != null) {
      return anyMatch.group(1);
    }

    return null;
  }

  /// 判断输入是否为B站短链接
  /// 
  /// [input] 用户输入的文本
  /// 返回true表示是短链接
  bool isShortLink(String input) {
    return input.contains('b23.tv/') || input.contains('b23.com/');
  }

  /// 从文本中提取B站短链接URL
  /// 
  /// 支持从混合文本中提取，例如：
  /// "【差评率100%的自助火锅-哔哩哔哩】 https://b23.tv/sne4c22"
  /// 
  /// [input] 包含短链接的文本
  /// 返回提取出的完整URL，如果未找到则返回null
  String? extractShortLinkUrl(String input) {
    // 1. 尝试匹配带http(s)前缀的短链接
    final urlPattern = RegExp(
      r'https?://b23\.(tv|com)/[a-zA-Z0-9]+',
      caseSensitive: false,
    );
    final match = urlPattern.firstMatch(input);
    if (match != null) {
      return match.group(0);
    }

    // 2. 尝试匹配不带http前缀的短链接
    final shortPattern = RegExp(
      r'b23\.(tv|com)/[a-zA-Z0-9]+',
      caseSensitive: false,
    );
    final shortMatch = shortPattern.firstMatch(input);
    if (shortMatch != null) {
      return 'https://${shortMatch.group(0)}';
    }

    return null;
  }

  /// 解析B站短链接，获取实际的视频URL
  /// 
  /// [shortUrl] 短链接URL或包含短链接的文本
  /// 返回解析后的完整视频URL，如果解析失败则返回null
  /// 
  /// 注意：此方法会发起网络请求
  Future<String?> resolveShortLink(String shortUrl) async {
    try {
      // 从文本中提取实际的短链接URL
      final url = extractShortLinkUrl(shortUrl) ?? shortUrl;

      // 确保URL带有scheme
      String processedUrl = url;
      if (!processedUrl.startsWith('http://') &&
          !processedUrl.startsWith('https://')) {
        processedUrl = 'https://$processedUrl';
      }

      final client = http.Client();
      try {
        // 1. 首先尝试不跟随重定向，获取Location头
        final request = http.Request('GET', Uri.parse(processedUrl));
        request.followRedirects = false;

        final streamedResponse = await client.send(request);

        // 检查重定向响应
        if (streamedResponse.statusCode >= 300 &&
            streamedResponse.statusCode < 400) {
          final location = streamedResponse.headers['location'];
          if (location != null) {
            return location;
          }
        }

        // 2. 如果没有重定向头，尝试完整请求
        // 某些短链接可能使用JavaScript重定向
        final response = await http.get(Uri.parse(processedUrl));

        // 从响应体中查找视频URL
        final bvPattern = RegExp(
          r'bilibili\.com/video/(BV[a-zA-Z0-9]{10,12})',
          caseSensitive: false,
        );
        final match = bvPattern.firstMatch(response.body);
        if (match != null) {
          return 'https://www.bilibili.com/video/${match.group(1)}';
        }

        return null;
      } finally {
        client.close();
      }
    } catch (e) {
      debugPrint('Error resolving short link: $e');
      return null;
    }
  }

  /// 从文本中提取所有BV号
  /// 
  /// [text] 要搜索的文本
  /// 返回找到的所有BV号列表（去重）
  List<String> extractAllBvids(String text) {
    if (text.isEmpty) return [];

    final bvPattern = RegExp(
      r'(BV[a-zA-Z0-9]{10,12})',
      caseSensitive: false,
    );

    final matches = bvPattern.allMatches(text);
    final bvids = matches.map((match) => match.group(1)!).toSet().toList();

    return bvids;
  }

  /// 验证BV号格式是否有效
  /// 
  /// [bvid] 要验证的BV号
  /// 返回true表示格式有效
  bool isValidBvid(String bvid) {
    if (bvid.isEmpty) return false;

    final pattern = RegExp(
      r'^BV[a-zA-Z0-9]{10,12}$',
      caseSensitive: false,
    );

    return pattern.hasMatch(bvid);
  }

  /// 规范化BV号格式（确保以"BV"开头且大小写正确）
  /// 
  /// [bvid] 要规范化的BV号
  /// 返回规范化后的BV号，如果格式无效则返回null
  String? normalizeBvid(String bvid) {
    if (bvid.isEmpty) return null;

    // 移除前后空格
    final trimmed = bvid.trim();

    // 如果不以BV开头，尝试添加
    String normalized = trimmed;
    if (!normalized.toUpperCase().startsWith('BV')) {
      normalized = 'BV$normalized';
    }

    // 验证格式
    if (!isValidBvid(normalized)) {
      return null;
    }

    // 确保BV前缀大写
    return 'BV${normalized.substring(2)}';
  }

  /// 完整解析方法（包含短链接处理）
  /// 
  /// [input] 用户输入的文本
  /// 返回解析出的BV号，如果无法解析或解析失败则返回null
  /// 
  /// 注意：如果输入是短链接，此方法会发起网络请求
  Future<String?> parseAsync(String input) async {
    if (input.isEmpty) return null;

    // 1. 检查是否为短链接
    if (isShortLink(input)) {
      final resolvedUrl = await resolveShortLink(input);
      if (resolvedUrl != null) {
        return parseBvid(resolvedUrl);
      }
      return null;
    }

    // 2. 直接解析BV号
    return parseBvid(input);
  }
}
