import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

/// 本地存储服务
class StorageService {
  SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// 初始化
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get _preferences {
    if (_prefs == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  /// 获取 SharedPreferences 实例（用于其他服务）
  SharedPreferences get prefs => _preferences;

  // ==================== 投票 Token ====================

  Future<void> setVoteToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _secureStorage.delete(key: ApiConfig.storageKeyVoteToken);
    } else {
      await _secureStorage.write(key: ApiConfig.storageKeyVoteToken, value: token);
    }
  }

  Future<String?> getVoteToken() async {
    return _secureStorage.read(key: ApiConfig.storageKeyVoteToken);
  }

  Future<void> clearVoteToken() async {
    await _secureStorage.delete(key: ApiConfig.storageKeyVoteToken);
  }

  // ==================== 主题设置 ====================

  /// 获取主题设置
  String? getTheme() {
    return _preferences.getString(ApiConfig.storageKeyTheme);
  }

  /// 保存主题设置
  Future<void> setTheme(String theme) async {
    await _preferences.setString(ApiConfig.storageKeyTheme, theme);
  }

  // ==================== API 服务器 ====================

  /// 获取自定义 API 地址
  String? getApiEndpoint() {
    return _preferences.getString(ApiConfig.storageKeyApiEndpoint);
  }

  /// 设置自定义 API 地址
  Future<void> setApiEndpoint(String? endpoint) async {
    if (endpoint == null || endpoint.isEmpty) {
      await _preferences.remove(ApiConfig.storageKeyApiEndpoint);
    } else {
      await _preferences.setString(ApiConfig.storageKeyApiEndpoint, endpoint);
    }
  }

  // ==================== 第一名显示 ====================

  /// 获取第一名显示设置 ('default' or 'custom')
  String getRank1Setting() {
    return _preferences.getString(ApiConfig.storageKeyRank1Setting) ?? 'custom';
  }

  /// 设置第一名显示设置
  Future<void> setRank1Setting(String setting) async {
    await _preferences.setString(ApiConfig.storageKeyRank1Setting, setting);
  }

  // ==================== 用户 ID ====================

  /// 获取用户 ID
  String? getUserId() {
    return _preferences.getString(ApiConfig.storageKeyUserId);
  }

  /// 设置用户 ID
  Future<void> setUserId(String? userId) async {
    if (userId == null || userId.isEmpty) {
      await _preferences.remove(ApiConfig.storageKeyUserId);
    } else {
      await _preferences.setString(ApiConfig.storageKeyUserId, userId);
    }
  }
}
