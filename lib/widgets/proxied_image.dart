import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../services/services.dart';
import 'altcha_dialog.dart';

/// 支持速率限制处理和 Altcha 验证的图片组件
/// 仅在 Web 端进行代理和验证处理，其他平台直接使用 Image.network
class ProxiedImage extends StatefulWidget {
  final String? imageUrl;
  final BoxFit fit;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final Widget? placeholder;

  const ProxiedImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.errorBuilder,
    this.placeholder,
  });

  @override
  State<ProxiedImage> createState() => _ProxiedImageState();
}

class _ProxiedImageState extends State<ProxiedImage> {
  Uint8List? _imageData;
  bool _isLoading = true;
  bool _hasError = false;
  Object? _error;
  String? _altchaSolution;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(ProxiedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _altchaSolution = null;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (widget.imageUrl == null || widget.imageUrl!.isEmpty) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _error = null;
    });

    // 非 Web 端直接使用原始 URL，不需要手动加载
    if (!kIsWeb) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final apiService = context.read<ApiService>();
      final proxiedUrl = ImageProxyService.convertImageUrl(
        widget.imageUrl,
        apiService.apiBase,
      );

      // 构建带 altcha 参数的 URL（如果有）
      final uri = Uri.parse(proxiedUrl);
      final finalUri = _altchaSolution != null
          ? uri.replace(
              queryParameters: {
                ...uri.queryParameters,
                'altcha': _altchaSolution!,
              },
            )
          : uri;

      final response = await http.get(finalUri);

      if (!mounted) return;

      if (response.statusCode == 200) {
        // 检查是否是图片内容
        final contentType = response.headers['content-type'] ?? '';
        if (contentType.startsWith('image/')) {
          setState(() {
            _imageData = response.bodyBytes;
            _isLoading = false;
            _hasError = false;
          });
        } else {
          // 可能是 JSON 错误响应
          _handleErrorResponse(response);
        }
      } else if (response.statusCode == 429) {
        // 速率限制，检查是否需要 CAPTCHA
        _handleRateLimitResponse(response);
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _error = Exception('HTTP ${response.statusCode}');
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _error = e;
        });
      }
    }
  }

  void _handleErrorResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final requiresCaptcha = json['requiresCaptcha'] as bool? ?? false;

      if (requiresCaptcha) {
        _showAltchaDialog();
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _error = Exception(json['error'] ?? 'Unknown error');
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _error = e;
      });
    }
  }

  void _handleRateLimitResponse(http.Response response) {
    try {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final requiresCaptcha = json['requiresCaptcha'] as bool? ?? false;

      if (requiresCaptcha) {
        _showAltchaDialog();
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _error = Exception('Rate limit exceeded');
        });
      }
    } catch (e) {
      // 无法解析 JSON，可能不是预期的响应格式
      setState(() {
        _isLoading = false;
        _hasError = true;
        _error = Exception('Rate limit exceeded');
      });
    }
  }

  Future<void> _showAltchaDialog() async {
    if (!mounted) return;

    final apiService = context.read<ApiService>();
    final altchaService = AltchaService(apiService);

    final solution = await AltchaDialog.show(context, altchaService);

    if (solution != null && mounted) {
      // 验证成功，使用新的 altcha 解决方案重新加载
      _altchaSolution = solution;
      _loadImage();
    } else if (mounted) {
      // 用户取消验证
      setState(() {
        _isLoading = false;
        _hasError = true;
        _error = Exception('Verification cancelled');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 非 Web 端直接使用 Image.network
    if (!kIsWeb) {
      final url = widget.imageUrl;
      if (url == null || url.isEmpty) {
        return _buildError();
      }
      return Image.network(
        url.replaceFirst('http:', 'https:'),
        fit: widget.fit,
        errorBuilder: widget.errorBuilder ?? (_, __, _) => _buildError(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder();
        },
      );
    }

    // Web 端使用手动加载的数据
    if (_isLoading) {
      return _buildPlaceholder();
    }

    if (_hasError || _imageData == null) {
      return _buildError();
    }

    return Image.memory(
      _imageData!,
      fit: widget.fit,
      errorBuilder: widget.errorBuilder ?? (_, __, _) => _buildError(),
    );
  }

  Widget _buildPlaceholder() {
    return widget.placeholder ??
        Container(
          color: Colors.grey[300],
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
  }

  Widget _buildError() {
    if (widget.errorBuilder != null) {
      return widget.errorBuilder!(context, _error ?? 'Unknown error', null);
    }
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
      ),
    );
  }
}
