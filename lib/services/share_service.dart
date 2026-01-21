import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';
import '../models/models.dart';
import '../widgets/share_card_template.dart';

/// 分享服务类
class ShareService {
  /// 分享视频完整信息（标题 + 链接 + 排名）
  Future<void> shareVideoInfo(LeaderboardItem item, {int? rank}) async {
    final text = _generateShareText(item, rank: rank);
    await SharePlus.instance.share(ShareParams(text: text));
  }

  /// 分享视频链接
  Future<void> shareVideoUrl(String bvid) async {
    final url = _getVideoUrl(bvid);
    await SharePlus.instance.share(ShareParams(text: url));
  }

  /// 复制 BV 号到剪贴板
  Future<void> copyBvid(String bvid) async {
    await Clipboard.setData(ClipboardData(text: bvid));
  }

  /// 复制视频链接到剪贴板
  Future<void> copyVideoUrl(String bvid) async {
    final url = _getVideoUrl(bvid);
    await Clipboard.setData(ClipboardData(text: url));
  }

  /// 复制完整信息到剪贴板
  Future<void> copyVideoInfo(LeaderboardItem item, {int? rank}) async {
    final text = _generateShareText(item, rank: rank);
    await Clipboard.setData(ClipboardData(text: text));
  }

  /// 生成并分享截图卡片
  Future<void> shareScreenshot(
    BuildContext context,
    LeaderboardItem item, {
    int? rank,
  }) async {
    try {
      // 创建截图控制器
      final screenshotController = ScreenshotController();

      // 生成截图
      final imageBytes = await screenshotController.captureFromWidget(
        MediaQuery(
          data: const MediaQueryData(),
          child: Material(
            child: ShareCardTemplate(item: item, rank: rank),
          ),
        ),
        delay: const Duration(milliseconds: 100),
      );

      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/share_card_${item.bvid}.png');
      await file.writeAsBytes(imageBytes);

      // 分享文件
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: '${item.title ?? item.bvid} - B站问号榜',
        ),
      );
    } catch (e) {
      debugPrint('生成分享截图失败: $e');
      rethrow;
    }
  }

  /// 生成视频链接
  String _getVideoUrl(String bvid) {
    return 'https://www.bilibili.com/video/$bvid';
  }

  /// 生成分享文本
  String _generateShareText(LeaderboardItem item, {int? rank}) {
    final buffer = StringBuffer();

    // 标题
    if (item.title != null && item.title!.isNotEmpty) {
      buffer.writeln('【${item.title}】');
      buffer.writeln();
    }

    // 排名信息
    if (rank != null) {
      buffer.writeln('📊 B站问号榜排名: #$rank');
    }

    // 抽象指数
    buffer.writeln('❓ 抽象指数: ${item.count}');

    // UP主
    if (item.ownerName != null && item.ownerName!.isNotEmpty) {
      buffer.writeln('👤 UP主: ${item.ownerName}');
    }

    // 数据统计
    if (item.viewCount != null || item.danmakuCount != null) {
      buffer.write('📈 ');
      if (item.viewCount != null) {
        buffer.write('播放: ${_formatCount(item.viewCount!)}');
      }
      if (item.danmakuCount != null) {
        if (item.viewCount != null) buffer.write(' | ');
        buffer.write('弹幕: ${_formatCount(item.danmakuCount!)}');
      }
      buffer.writeln();
    }

    buffer.writeln();
    buffer.writeln('🔗 ${_getVideoUrl(item.bvid)}');
    buffer.writeln();
    buffer.write('来自「B站问号榜」客户端');

    return buffer.toString();
  }

  /// 格式化数字
  String _formatCount(int count) {
    if (count >= 100000000) {
      final v = count / 100000000;
      return '${v >= 10 ? v.round() : v.toStringAsFixed(1)}亿';
    }
    if (count >= 10000) {
      final v = count / 10000;
      return '${v >= 10 ? v.round() : v.toStringAsFixed(1)}万';
    }
    return count.toString();
  }
}
