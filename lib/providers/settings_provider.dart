import 'package:flutter/foundation.dart';
import '../config/constants.dart';
import '../services/services.dart';

/// 设置状态管理
class SettingsProvider extends ChangeNotifier {
  final StorageService _storageService;
  final ApiService _apiService;

  String _rank1Setting = 'custom';
  String _apiEndpoint = ApiConfig.defaultApiBase;
  String? _userId;
  String? _voteToken;

  SettingsProvider(this._storageService, this._apiService) {
    _loadSettings();
  }

  // Getters

  String get rank1Setting => _rank1Setting;
  String get apiEndpoint => _apiEndpoint;
  String? get userId => _userId;
  String? get voteToken => _voteToken;
  bool get isRank1Custom => _rank1Setting == 'custom';

  Future<void> _loadSettings() async {
    // 第一名显示设置
    _rank1Setting = _storageService.getRank1Setting();

    // API 端点
    final savedEndpoint = _storageService.getApiEndpoint();
    if (savedEndpoint != null && savedEndpoint.isNotEmpty) {
      _apiEndpoint = savedEndpoint;
      _apiService.updateApiBase(savedEndpoint);
    }

    // 用户 ID
    _userId = _storageService.getUserId();

    // 投票 Token
    _voteToken = await _storageService.getVoteToken();
    _apiService.updateVoteToken(_voteToken);

    notifyListeners();
  }

  /// 设置第一名显示
  Future<void> setRank1Setting(String setting) async {
    _rank1Setting = setting;
    await _storageService.setRank1Setting(setting);
    notifyListeners();
  }

  /// 设置 API 端点
  Future<void> setApiEndpoint(String endpoint) async {
    final newEndpoint = endpoint.isEmpty ? ApiConfig.defaultApiBase : endpoint;
    _apiEndpoint = newEndpoint;
    _apiService.updateApiBase(newEndpoint);

    if (endpoint.isEmpty || endpoint == ApiConfig.defaultApiBase) {
      await _storageService.setApiEndpoint(null);
    } else {
      await _storageService.setApiEndpoint(endpoint);
    }
    notifyListeners();
  }

  /// 设置用户 ID
  Future<void> setUserId(String? userId) async {
    _userId = userId;
    await _storageService.setUserId(userId);
    notifyListeners();
  }

  /// 设置投票 Token
  Future<void> setVoteToken(String? token) async {
    _voteToken = token?.trim().isEmpty == true ? null : token;
    await _storageService.setVoteToken(_voteToken);
    _apiService.updateVoteToken(_voteToken);
    notifyListeners();
  }

  /// 重置 API 端点为默认
  Future<void> resetApiEndpoint() async {
    await setApiEndpoint(ApiConfig.defaultApiBase);
  }
}
