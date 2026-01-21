import 'package:flutter/foundation.dart';

class PwaInstallService extends ChangeNotifier {
  bool get isInstallPromptAvailable => false;
  bool get isStandaloneMode => false;
  bool get isIosDevice => false;

  Future<void> promptInstall() async {}
}
