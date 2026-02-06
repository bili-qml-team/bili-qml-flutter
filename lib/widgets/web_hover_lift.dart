import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Web 端轻量悬停抬升动效
class WebHoverLift extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final double scale;
  final double slideY;
  final Duration duration;
  final Curve curve;
  final MouseCursor cursor;

  const WebHoverLift({
    super.key,
    required this.child,
    this.enabled = true,
    this.scale = 1.01,
    this.slideY = -0.01,
    this.duration = const Duration(milliseconds: 130),
    this.curve = Curves.easeOutCubic,
    this.cursor = SystemMouseCursors.click,
  });

  @override
  State<WebHoverLift> createState() => _WebHoverLiftState();
}

class _WebHoverLiftState extends State<WebHoverLift> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !widget.enabled) {
      return widget.child;
    }

    return MouseRegion(
      cursor: widget.cursor,
      onEnter: (_) {
        if (_isHovering) return;
        setState(() => _isHovering = true);
      },
      onExit: (_) {
        if (!_isHovering) return;
        setState(() => _isHovering = false);
      },
      child: AnimatedScale(
        scale: _isHovering ? widget.scale : 1,
        duration: widget.duration,
        curve: widget.curve,
        child: AnimatedSlide(
          offset: _isHovering ? Offset(0, widget.slideY) : Offset.zero,
          duration: widget.duration,
          curve: widget.curve,
          child: widget.child,
        ),
      ),
    );
  }
}
