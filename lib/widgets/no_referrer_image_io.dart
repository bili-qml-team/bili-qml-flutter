import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class NoReferrerImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final WidgetBuilder? placeholder;
  final WidgetBuilder? errorWidget;

  const NoReferrerImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      width: width,
      height: height,
      placeholder:
          placeholder == null ? null : (context, url) => placeholder!(context),
      errorWidget:
          errorWidget == null
              ? null
              : (context, url, error) => errorWidget!(context),
    );
  }
}
