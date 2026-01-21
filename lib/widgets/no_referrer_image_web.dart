// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class NoReferrerImage extends StatefulWidget {
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
  State<NoReferrerImage> createState() => _NoReferrerImageState();
}

class _NoReferrerImageState extends State<NoReferrerImage> {
  static int _viewIdSeed = 0;
  late final String _viewType;
  late final html.ImageElement _imageElement;
  bool _loaded = false;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _viewType = 'no-referrer-image-${_viewIdSeed++}';
    _imageElement = html.ImageElement()
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.objectFit = _cssFit(widget.fit);
    _imageElement.setAttribute('referrerpolicy', 'no-referrer');
    _imageElement.src = widget.imageUrl;

    _imageElement.onLoad.listen((_) {
      if (mounted) {
        setState(() => _loaded = true);
      }
    });
    _imageElement.onError.listen((_) {
      if (mounted) {
        setState(() => _error = true);
      }
    });

    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(_viewType, (_) {
      return _imageElement;
    });
  }

  @override
  void didUpdateWidget(NoReferrerImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _loaded = false;
      _error = false;
      _imageElement.src = widget.imageUrl;
    }
    if (oldWidget.fit != widget.fit) {
      _imageElement.style.objectFit = _cssFit(widget.fit);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return widget.errorWidget?.call(context) ?? const SizedBox.shrink();
    }
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          HtmlElementView(viewType: _viewType),
          if (!_loaded)
            widget.placeholder?.call(context) ?? const SizedBox.shrink(),
        ],
      ),
    );
  }

  String _cssFit(BoxFit? fit) {
    switch (fit) {
      case BoxFit.contain:
        return 'contain';
      case BoxFit.fill:
        return 'fill';
      case BoxFit.none:
        return 'none';
      case BoxFit.scaleDown:
        return 'scale-down';
      case BoxFit.cover:
      default:
        return 'cover';
    }
  }
}
