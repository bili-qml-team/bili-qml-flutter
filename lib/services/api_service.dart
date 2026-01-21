import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/models.dart';

/// API 服务类
class ApiService {
  String _apiBase;

  ApiService({String? apiBase})
    : _apiBase = apiBase ?? ApiConfig.defaultApiBase;

  /// 更新 API 地址
  void updateApiBase(String apiBase) {
    _apiBase = apiBase;
  }

  /// 获取当前 API 地址
  String get apiBase => _apiBase;

  /// 通用请求头
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  String? get _originParam => kIsWeb ? Uri.base.origin : null;

  Map<String, String> _attachOriginParam(Map<String, String> params) {
    final origin = _originParam;
    if (origin == null) {
      return params;
    }
    return {...params, 'origin': origin};
  }

  /// 获取投票状态
  Future<UserStatus> getStatus(String bvid, String? userId) async {
    final uri = Uri.parse('$_apiBase/status').replace(
      queryParameters: _attachOriginParam({
        'bvid': bvid,
        if (userId != null) 'userId': userId,
        '_t': DateTime.now().millisecondsSinceEpoch.toString(),
      }),
    );

    final response = await http.get(uri, headers: _headers);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    if (json['success'] == true) {
      return UserStatus.fromJson(json);
    } else {
      throw ApiException(json['error'] as String? ?? 'Unknown error');
    }
  }

  /// 投票
  Future<ApiResponse> vote(String bvid, String userId, {String? altcha}) async {
    return _voteRequest('vote', bvid, userId, altcha: altcha);
  }

  /// 取消投票
  Future<ApiResponse> unvote(
    String bvid,
    String userId, {
    String? altcha,
  }) async {
    return _voteRequest('unvote', bvid, userId, altcha: altcha);
  }

  Future<ApiResponse> _voteRequest(
    String endpoint,
    String bvid,
    String userId, {
    String? altcha,
  }) async {
    final uri = Uri.parse('$_apiBase/$endpoint');
    final body = _attachOriginParam({
      'bvid': bvid,
      'userId': userId,
      if (altcha != null) 'altcha': altcha,
    });

    final response = await http.post(
      uri,
      headers: _headers,
      body: jsonEncode(body),
    );

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return ApiResponse.fromJson(json, response.statusCode);
  }

  /// 获取排行榜
  Future<LeaderboardResponse> getLeaderboard(
    LeaderboardRange range, {
    String? altcha,
    int page = 1,
  }) async {
    // API 支持的页数范围是 1-10
    final validPage = page.clamp(1, 10);

    final queryParams = {
      'range': range.value,
      'type': '2', // 仅返回 BVID 和票数
      'page': validPage.toString(),
      '_t': DateTime.now().millisecondsSinceEpoch.toString(), // 防止缓存
    };
    if (altcha != null) {
      queryParams['altcha'] = altcha;
    }

    final uri = Uri.parse(
      '$_apiBase/leaderboard',
    ).replace(queryParameters: _attachOriginParam(queryParams));

    debugPrint('API Request URL: $uri');
    final response = await http.get(uri, headers: _headers);
    debugPrint('API Response Status: ${response.statusCode}, Body length: ${response.body.length}');
    
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return LeaderboardResponse.fromJson(json, response.statusCode);
  }

  /// 获取 Altcha 挑战
  Future<AltchaChallenge> getAltchaChallenge() async {
    final uri = Uri.parse(
      '$_apiBase/altcha/challenge',
    ).replace(queryParameters: _attachOriginParam({}));
    final response = await http.get(uri, headers: _headers);
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    return AltchaChallenge.fromJson(json);
  }

  /// 获取 B站视频信息
  Future<VideoInfo?> getBilibiliVideoInfo(String bvid) async {
    try {
      final Uri uri;
      if (kIsWeb) {
        final baseUri = Uri.parse(_apiBase);
        final rawPath = baseUri.path.replaceAll(RegExp(r'/+$'), '');
        final basePath = rawPath == '/' ? '' : rawPath;
        final proxyPath =
            basePath.isEmpty
                ? '/api/x/web-interface/view'
                : '$basePath/x/web-interface/view';
        uri = baseUri.replace(
          path: proxyPath,
          queryParameters: _attachOriginParam({'bvid': bvid}),
        );
      } else {
        uri = Uri.parse(
          '${ApiConfig.bilibiliApiBase}/x/web-interface/view?bvid=$bvid',
        );
      }
      final response = await http.get(uri);
      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['code'] == 0 && json['data'] != null) {
        return VideoInfo.fromBilibiliApi(json);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

/// API 响应
class ApiResponse {
  final bool success;
  final String? error;
  final bool requiresCaptcha;
  final int statusCode;

  ApiResponse({
    required this.success,
    this.error,
    this.requiresCaptcha = false,
    required this.statusCode,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json, int statusCode) {
    return ApiResponse(
      success: json['success'] as bool? ?? false,
      error: json['error'] as String?,
      requiresCaptcha: json['requiresCaptcha'] as bool? ?? false,
      statusCode: statusCode,
    );
  }
}

/// 排行榜响应
class LeaderboardResponse {
  final bool success;
  final List<LeaderboardItem> list;
  final bool requiresCaptcha;
  final String? error;
  final int statusCode;

  LeaderboardResponse({
    required this.success,
    required this.list,
    this.requiresCaptcha = false,
    this.error,
    required this.statusCode,
  });

  factory LeaderboardResponse.fromJson(
    Map<String, dynamic> json,
    int statusCode,
  ) {
    final listJson = json['list'] as List<dynamic>? ?? [];
    final items = listJson
        .map((e) => LeaderboardItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return LeaderboardResponse(
      success: json['success'] as bool? ?? false,
      list: items,
      requiresCaptcha: json['requiresCaptcha'] as bool? ?? false,
      error: json['error'] as String?,
      statusCode: statusCode,
    );
  }
}

/// Altcha 挑战
class AltchaChallenge {
  final String algorithm;
  final String challenge;
  final String salt;
  final String signature;
  final int maxNumber;

  AltchaChallenge({
    required this.algorithm,
    required this.challenge,
    required this.salt,
    required this.signature,
    required this.maxNumber,
  });

  factory AltchaChallenge.fromJson(Map<String, dynamic> json) {
    return AltchaChallenge(
      algorithm: json['algorithm'] as String,
      challenge: json['challenge'] as String,
      salt: json['salt'] as String,
      signature: json['signature'] as String,
      maxNumber: json['maxnumber'] as int,
    );
  }
}

/// API 异常
class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
