import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'api_service.dart';

/// Altcha 验证服务
class AltchaService {
  final ApiService _apiService;

  AltchaService(this._apiService);

  /// 获取挑战并计算解决方案
  Future<String> solveChallenge({
    void Function(double progress)? onProgress,
  }) async {
    // 1. 获取挑战
    final challenge = await _apiService.getAltchaChallenge();

    // 2. 计算 PoW 解决方案
    final solution = await _computeSolution(challenge, onProgress: onProgress);

    return solution;
  }

  /// 计算 PoW 解决方案
  Future<String> _computeSolution(
    AltchaChallenge challenge, {
    void Function(double progress)? onProgress,
  }) async {
    final salt = challenge.salt;
    final targetHash = challenge.challenge;
    final maxNumber = challenge.maxNumber;

    for (int number = 0; number <= maxNumber; number++) {
      // 计算 SHA-256 哈希
      final data = '$salt$number';
      final bytes = utf8.encode(data);
      final digest = sha256.convert(bytes);
      final hashHex = digest.toString();

      if (hashHex == targetHash) {
        // 找到解决方案，返回 Base64 编码的 JSON
        final solution = {
          'algorithm': challenge.algorithm,
          'challenge': challenge.challenge,
          'number': number,
          'salt': challenge.salt,
          'signature': challenge.signature,
        };
        return base64Encode(utf8.encode(jsonEncode(solution)));
      }

      // 每 1000 次迭代报告进度
      if (number % 1000 == 0) {
        onProgress?.call(number / maxNumber);
        // 让出控制权，避免阻塞 UI
        await Future.delayed(Duration.zero);
      }
    }

    throw AltchaException('Failed to solve challenge');
  }
}

/// Altcha 异常
class AltchaException implements Exception {
  final String message;

  AltchaException(this.message);

  @override
  String toString() => 'AltchaException: $message';
}
