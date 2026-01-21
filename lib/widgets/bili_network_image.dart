import 'package:flutter/material.dart';

import 'bili_network_image_web.dart'
    if (dart.library.io) 'bili_network_image_stub.dart';

/// 带有平台感知的网络图片组件
///
/// - Web 端：使用 HTML img 标签并设置 referrerpolicy="no-referrer"
/// - 其他平台：使用 CachedNetworkImage
class BiliNetworkImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final Widget Function(BuildContext context)? placeholder;
  final Widget Function(BuildContext context, Object error)? errorWidget;

  const BiliNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    // 调用平台特定的实现
    return buildPlatformImage(
      context: context,
      imageUrl: imageUrl.replaceFirst('http:', 'https:'),
      fit: fit ?? BoxFit.cover,
      placeholder: placeholder,
      errorWidget: errorWidget,
    );
  }
}
