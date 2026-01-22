import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

final Set<String> _registeredViewTypes = <String>{};

/// Web 端实现 - 使用 HTML img 标签并设置 referrerpolicy="no-referrer"
Widget buildPlatformImage({
  required BuildContext context,
  required String imageUrl,
  required BoxFit fit,
  Widget Function(BuildContext context)? placeholder,
  Widget Function(BuildContext context, Object error)? errorWidget,
  bool isHighPriority = false,
}) {
  return _WebImage(
    imageUrl: imageUrl,
    fit: fit,
    placeholder: placeholder,
    errorWidget: errorWidget,
    isHighPriority: isHighPriority,
  );
}

class _WebImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final Widget Function(BuildContext context)? placeholder;
  final Widget Function(BuildContext context, Object error)? errorWidget;
  final bool isHighPriority;

  const _WebImage({
    required this.imageUrl,
    required this.fit,
    this.placeholder,
    this.errorWidget,
    this.isHighPriority = false,
  });

  @override
  State<_WebImage> createState() => _WebImageState();
}

class _WebImageState extends State<_WebImage> {
  late final String _viewType;
  bool _hasError = false;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _viewType =
        'bili-img-${Object.hash(widget.imageUrl, widget.fit, widget.isHighPriority)}';
    _registerViewFactory();
  }

  void _registerViewFactory() {
    if (_registeredViewTypes.contains(_viewType)) {
      return;
    }
    _registeredViewTypes.add(_viewType);
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final img = web.HTMLImageElement()
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = _getObjectFit()
        ..style.pointerEvents = 'none'
        ..setAttribute('loading', widget.isHighPriority ? 'eager' : 'lazy')
        ..setAttribute('decoding', 'async')
        ..setAttribute('fetchpriority', widget.isHighPriority ? 'high' : 'auto')
        ..setAttribute('referrerpolicy', 'no-referrer')
        ..src = widget.imageUrl;

      img.onLoad.listen((_) {
        if (mounted) {
          setState(() => _isLoaded = true);
        }
      });

      img.onError.listen((_) {
        if (mounted) {
          setState(() => _hasError = true);
        }
      });

      return img;
    });
  }

  String _getObjectFit() {
    switch (widget.fit) {
      case BoxFit.cover:
        return 'cover';
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.fitWidth:
      case BoxFit.fitHeight:
        return 'cover';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return widget.errorWidget?.call(
            context,
            Exception('Image load failed'),
          ) ??
          Container(
            color: Colors.grey[300],
            child: const Center(
              child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
            ),
          );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (!_isLoaded && widget.placeholder != null)
          widget.placeholder!(context),
        HtmlElementView(viewType: _viewType),
      ],
    );
  }
}
