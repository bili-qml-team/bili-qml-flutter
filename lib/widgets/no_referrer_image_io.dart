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
    return Image.network(
      imageUrl,
      fit: fit,
      width: width,
      height: height,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return placeholder?.call(context) ?? const SizedBox.shrink();
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget?.call(context) ?? const SizedBox.shrink();
      },
    );
  }
}
