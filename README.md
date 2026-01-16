# B站问号榜 Flutter 客户端 (Bili QML App)

这是一个基于 Flutter 开发的 B站问号榜客户端，支持 **Android** 和 **Windows** 平台。  
IOS因为本人无MAC，所以无法测试，所以弃了。

## 📋 环境要求

在开始之前，请确保您的开发环境已准备就绪：

### 通用要求
- **Flutter SDK**: 3.10.0 或更高版本
- **Dart SDK**: 3.0.0 或更高版本
- **IDE**: VS Code (推荐) 或 Android Studio / IntelliJ IDEA

### 平台特定要求
- **Android**: Android Studio, Android SDK, 改好的 AVD 或真机
- **Windows**: Visual Studio 2022 (需要安装 "C++ 桌面开发" 工作负载)
- **iOS**: macOS, Xcode, CocoaPods

## 🛠️ 项目初始化

1. **获取代码**
   ```bash
   git clone https://github.com/bili-qml-team/bili-qml-flutter.git
   cd bili-qml-flutter
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

## 🚀 开发运行

### Windows
```bash
flutter run -d windows
```

### Android
确保已连接设备或启动模拟器：
```bash
flutter run -d android
```

### iOS (仅 macOS)
确保已启动模拟器或连接 iOS 设备：
```bash
flutter run -d ios
```

## 📦 构建发布

### 1. Windows (.exe)

构建发布版本：
```bash
flutter build windows --release
```
构建产物位于：`build/windows/runner/Release/`
- 输出包含 `bili_qml_app.exe` 和必要的 `.dll` 文件
- `data` 文件夹包含资源文件
- 发布时需要打包这整个目录

### 2. Android (.apk)

构建 APK：
```bash
flutter build apk --release
```
构建产物位于：`build/app/outputs/flutter-apk/app-release.apk`

构建 App Bundle (用于上传 Google Play)：
```bash
flutter build appbundle --release
```

> **注意**: 正式发布前需要配置签名密钥。请参考 [Android 签名文档](https://flutter.dev/docs/deployment/android#signing-the-app)。

### 3. iOS (.ipa) (仅 macOS)

构建 iOS 归档：
```bash
flutter build ios --release
```
然后需要在 Xcode 中打开 `ios/Runner.xcworkspace` 进行归档 (Product -> Archive) 和发布。

> **注意**: 需要有效的 Apple 开发者账号和证书配置。

## 🔧 常见问题

### Windows 构建失败
- 检查是否安装了 Visual Studio 的 C++ 工作负载
- 运行 `flutter doctor` 检查环境问题

### 依赖报错
- 尝试清理缓存：
  ```bash
  flutter clean
  flutter pub get
  ```

### 网络问题
- 由于应用需要访问 B站 API，请确保网络环境正常
- Android 模拟器可能需要配置代理

## 📝 功能特性

- **多榜单查看**: 实时榜、日榜、周榜、月榜
- **视频详情**: 清晰显示，支持跳转浏览器播放
- **交互投票**: 悬浮按钮快速投票/取消
- **查找**: 支持查找指定BV号的视频数据
- **设置自定义**:
  - 主题切换 (深色/浅色/跟随系统)
  - 自定义 API 服务器
  - 用户 UID 绑定
- **安全验证**: 集成 Altcha 人机验证

---
如有问题，请提交 Issue 或检查日志输出。
