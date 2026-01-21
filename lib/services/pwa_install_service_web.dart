import 'package:flutter/foundation.dart';

// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class PwaInstallService extends ChangeNotifier {
  html.Event? _deferredPrompt;
  bool _isStandaloneMode = false;
  final bool _isIosDevice = _detectIosDevice();

  bool get isInstallPromptAvailable => _deferredPrompt != null;
  bool get isStandaloneMode => _isStandaloneMode;
  bool get isIosDevice => _isIosDevice;

  PwaInstallService() {
    _isStandaloneMode = _checkStandaloneMode();
    html.window.addEventListener(
      'beforeinstallprompt',
      _handleBeforeInstallPrompt,
    );
    html.window.addEventListener('appinstalled', _handleAppInstalled);
  }

  Future<void> promptInstall() async {
    final promptEvent = _deferredPrompt;
    if (promptEvent == null) {
      return;
    }

    _deferredPrompt = null;
    notifyListeners();

    try {
      (promptEvent as dynamic).prompt();
    } catch (error) {
      debugPrint('Failed to trigger install prompt: $error');
    }
  }

  void _handleBeforeInstallPrompt(html.Event event) {
    event.preventDefault();
    _deferredPrompt = event;
    notifyListeners();
  }

  void _handleAppInstalled(html.Event event) {
    _deferredPrompt = null;
    _updateStandaloneMode(true);
  }

  void _updateStandaloneMode([bool? value]) {
    final nextValue = value ?? _checkStandaloneMode();
    if (_isStandaloneMode == nextValue) {
      return;
    }

    _isStandaloneMode = nextValue;
    notifyListeners();
  }

  static bool _checkStandaloneMode() {
    final isStandalone = html.window
        .matchMedia('(display-mode: standalone)')
        .matches;
    // navigator.standalone is an iOS Safari-specific property
    // Use try-catch to safely check for its existence
    bool isIosStandalone = false;
    try {
      final dynamic navigator = html.window.navigator;
      // Check if 'standalone' property exists before accessing it
      if (_hasProperty(navigator, 'standalone')) {
        isIosStandalone = navigator.standalone == true;
      }
    } catch (e) {
      // Property doesn't exist or other error - treat as not standalone
      isIosStandalone = false;
    }
    return isStandalone || isIosStandalone;
  }

  static bool _hasProperty(dynamic obj, String propertyName) {
    try {
      // Use JavaScript's 'in' operator behavior via hasOwnProperty or checking undefined
      final dynamic jsObj = obj;
      return jsObj.hasOwnProperty(propertyName) == true ||
          (jsObj as dynamic)[propertyName] != null;
    } catch (e) {
      return false;
    }
  }

  static bool _detectIosDevice() {
    final userAgent = html.window.navigator.userAgent.toLowerCase();
    final isIos =
        userAgent.contains('iphone') ||
        userAgent.contains('ipad') ||
        userAgent.contains('ipod');
    if (isIos) {
      return true;
    }

    return userAgent.contains('macintosh') && userAgent.contains('mobile');
  }

  @override
  void dispose() {
    html.window.removeEventListener(
      'beforeinstallprompt',
      _handleBeforeInstallPrompt,
    );
    html.window.removeEventListener('appinstalled', _handleAppInstalled);
    super.dispose();
  }
}
