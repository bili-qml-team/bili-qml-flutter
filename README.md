<p align="center">
  <img src="icons/button-icon.png" width="100" height="100" alt="Bilibili Q-Mark List Logo">
</p>

<h1 align="center">B站问号榜 Flutter 客户端</h1>

<p align="center">
  <strong>分享抽象的视频，自动同步弹幕，打造Bilibili的抽象视频排行榜。</strong>
</p>

---

这是一个基于 Flutter 开发的 B站问号榜客户端，支持 **Android**、**Windows**、**Linux** 和 **Web** 平台。  
iOS 因为开发者无 Mac，所以无法测试，暂不支持。


# 使用教程
前往 [Releases](https://github.com/bili-qml-team/bili-qml-flutter/releases) 下载
   * Windows版解压后运行 **bili_qml_app.exe**
   * 安卓版安装APK即可
   * Web版可通过在线地址访问（暂无）

# 开发教程

## 📋 环境要求

在开始之前，请确保您的开发环境已准备就绪：

### 通用要求
- **Flutter SDK**: 3.10.0 或更高版本
- **Dart SDK**: 3.0.0 或更高版本
- **IDE**: VS Code (推荐) 或 Android Studio / IntelliJ IDEA

### 平台特定要求
- **Android**: Android Studio, Android SDK, 配置好的 AVD 或真机
- **Windows**: Visual Studio 2022 (需要安装 "C++ 桌面开发" 工作负载)
- **Linux**: Clang, CMake, Ninja, pkg-config, GTK3 开发库
- **iOS**: macOS, Xcode, CocoaPods
- **Web**: Chrome 或其他现代浏览器

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

### Linux
首先安装必要的依赖：
```bash
# Ubuntu/Debian
sudo apt-get install clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev fonts-noto-cjk

# Fedora
sudo dnf install clang cmake ninja-build pkgconfig gtk3-devel xz-devel google-noto-sans-cjk-fonts

# Arch Linux
sudo pacman -S clang cmake ninja pkgconf gtk3 xz noto-fonts-cjk
```
然后运行：
```bash
flutter run -d linux
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

### Web
在浏览器中运行：
```bash
flutter run -d chrome
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

### 3. Linux

确保已安装构建依赖（见上方开发运行部分），然后构建：
```bash
flutter build linux --release
```
构建产物位于：`build/linux/x64/release/bundle/`
- 输出包含 `bili_qml_app` 可执行文件和 `lib/` 目录
- `data` 文件夹包含资源文件
- 发布时需要打包整个 `bundle` 目录

> **注意**: 用户运行时需要安装中文字体以确保中文正常显示：
> ```bash
> # Ubuntu/Debian
> sudo apt-get install fonts-noto-cjk
> 
> # Fedora
> sudo dnf install google-noto-sans-cjk-fonts
> 
> # Arch Linux
> sudo pacman -S noto-fonts-cjk
> ```

### 4. Web

构建 Web 版本：
```bash
flutter build web --release
```
构建产物位于：`build/web/`
- 输出包含 `index.html` 和必要的资源文件
- 可直接部署到任何静态网站托管服务（如 GitHub Pages、Vercel、Netlify 等）

> **注意**: 部署时可能需要配置 CORS 代理以访问 B站 API。

### 5. iOS (.ipa) (仅 macOS)

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
