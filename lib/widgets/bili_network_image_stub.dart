import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// 非 Web 端实现 - 使用 CachedNetworkImage
Widget buildPlatformImage({
  required BuildContext context,
  required String imageUrl,
  required BoxFit fit,
  Widget Function(BuildContext context)? placeholder,
  Widget Function(BuildContext context, Object error)? errorWidget,
}) {
  return CachedNetworkImage(
    imageUrl: imageUrl,
    fit: fit,
    placeholder: placeholder != null
        ? (context, url) => placeholder(context)
        : (context, url) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
    errorWidget: errorWidget != null
        ? (context, url, error) => errorWidget(context, error)
        : (context, url, error) => Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          ),
  );
}
