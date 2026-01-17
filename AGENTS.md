# Agent Guidelines for bili-qml-flutter

This document provides guidelines for AI coding agents working on the B站问号榜 (Bilibili Question Mark List) Flutter application.

## Project Overview

- **Type**: Multi-platform Flutter application (Android, iOS, Windows, Linux, Web)
- **Purpose**: Bilibili video leaderboard/ranking client with voting functionality
- **Language**: Dart 3.10.7+
- **Framework**: Flutter 3.38.7+
- **State Management**: Provider pattern
- **Architecture**: Clean architecture (Models, Services, Providers, UI)

## Build, Lint & Test Commands

### Development
```bash
# Get dependencies
flutter pub get

# Run the app (debug mode)
flutter run

# Run on specific platform
flutter run -d windows
flutter run -d chrome
flutter run -d android
flutter run -d linux
```

### Building
```bash
# Build for production
flutter build apk               # Android APK
flutter build appbundle         # Android App Bundle
flutter build windows           # Windows executable
flutter build linux             # Linux executable
flutter build web               # Web bundle
flutter build ios               # iOS (requires macOS)

# Build for specific configuration
flutter build apk --release
flutter build windows --profile
```

### Linting & Analysis
```bash
# Run static analysis
flutter analyze

# Format code
dart format lib/ test/

# Check formatting without changes
dart format --output=none --set-exit-if-changed lib/ test/
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/widget_test.dart

# Run tests with coverage
flutter test --coverage

# Run tests in verbose mode
flutter test --verbose
```

### Cleanup
```bash
# Clean build artifacts
flutter clean

# Clean and reinstall dependencies
flutter clean && flutter pub get
```

## Project Structure

```
lib/
├── config/         # Constants, API endpoints, enums
├── models/         # Data models with JSON serialization
├── providers/      # State management (Provider pattern)
├── screens/        # Full-page UI screens
├── services/       # Business logic and API communication
├── theme/          # App theming and colors
├── widgets/        # Reusable UI components
└── main.dart       # Application entry point
```

## Code Style Guidelines

### General Principles
- Follow the official Flutter style guide
- Use `flutter_lints` package for code quality (already configured)
- Prioritize readability and maintainability
- Chinese comments are acceptable for domain-specific logic

### Imports
```dart
// 1. Dart SDK imports
import 'dart:convert';
import 'package:flutter/material.dart';

// 2. External package imports
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

// 3. Relative imports (use barrel exports)
import '../config/constants.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../providers/providers.dart';
```

**Rules:**
- Use barrel exports (`models.dart`, `services.dart`, etc.) for cleaner imports
- Prefix imports when needed (e.g., `as http`)
- Group imports by type with blank lines

### Naming Conventions
```dart
// Classes: PascalCase
class LeaderboardProvider extends ChangeNotifier {}
class ApiService {}

// Files: snake_case
// leaderboard_provider.dart
// api_service.dart

// Variables & functions: camelCase
String apiBase;
Future<void> fetchLeaderboard() {}

// Private members: prefix with underscore
String _apiBase;
void _loadVideoDetails() {}

// Constants: lowerCamelCase
const String defaultApiBase = 'https://api.example.com';

// Enums: PascalCase for type, camelCase for values
enum LeaderboardRange { realtime, daily, weekly, monthly }
```

### Formatting
- Use `dart format` for consistent formatting (no custom configuration)
- Max line length: 80 characters (Dart default)
- Use trailing commas for better formatting and diffs
- Single quotes for strings (unless interpolation or escaping needed)

### Types
```dart
// ✓ Always specify types for class members
class VideoCard {
  final String bvid;
  final int count;
}

// ✓ Use type inference for local variables when obvious
var items = <LeaderboardItem>[];
final response = await apiService.getLeaderboard();

// ✓ Prefer final over var when immutable
final apiService = ApiService();

// ✓ Use nullable types explicitly
String? title;
int? viewCount;

// ✓ Use required for non-nullable parameters
LeaderboardItem({
  required this.bvid,
  required this.count,
  this.title,  // Optional nullable
});
```

### Error Handling
```dart
// ✓ Use try-catch for async operations
try {
  final response = await apiService.getLeaderboard();
  if (response.success) {
    _items = response.list;
  } else {
    _error = response.error ?? 'Unknown error';
  }
} catch (e) {
  _error = 'Network error: ${e.toString()}';
}

// ✓ Custom exceptions for domain errors
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}

// ✓ Use debugPrint for non-critical logging
debugPrint('Failed to load video info: $e');

// ✗ Avoid print statements in production code
```

### Async/Await
```dart
// ✓ Always use async/await, not .then()
Future<void> fetchLeaderboard() async {
  _isLoading = true;
  notifyListeners();
  
  try {
    final response = await _apiService.getLeaderboard(_currentRange);
    _items = response.list;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

// ✓ Mark functions async only when needed
Future<void> refresh() async {
  await fetchLeaderboard();
}

// ✓ Use Future.wait for parallel operations
await Future.wait([
  fetchUserStatus(),
  fetchLeaderboard(),
]);
```

### State Management (Provider)
```dart
// ✓ Extend ChangeNotifier for state classes
class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();  // Always notify after state changes
  }
}

// ✓ Use private fields with public getters
// ✓ Call notifyListeners() after state modifications
// ✓ Inject services via constructor
class LeaderboardProvider extends ChangeNotifier {
  final ApiService _apiService;
  
  LeaderboardProvider(this._apiService);
}
```

### JSON Serialization
```dart
// ✓ Use factory constructors for JSON deserialization
factory LeaderboardItem.fromJson(Map<String, dynamic> json) {
  return LeaderboardItem(
    bvid: json['bvid'] as String,
    count: json['count'] as int,
    title: json['title'] as String?,
  );
}

// ✓ Use explicit type casting with 'as'
// ✓ Handle nullable fields appropriately
```

### Widget Best Practices
```dart
// ✓ Use const constructors when possible
const HomeScreen();

// ✓ Extract complex widgets to separate files
// widgets/video_card.dart
class VideoCard extends StatelessWidget {
  const VideoCard({super.key, required this.item});
  
  final LeaderboardItem item;
  
  @override
  Widget build(BuildContext context) {
    // Widget tree
  }
}

// ✓ Use StatelessWidget by default, StatefulWidget only when needed
// ✓ Keep build methods clean and readable
// ✓ Extract long widget trees into methods or separate widgets
```

## Platform-Specific Notes

### Android
- Build system: Gradle with Kotlin DSL
- Min SDK: Set by Flutter
- Signing: Configure `android/key.properties` for release builds

### Windows
- Build system: CMake with C++17
- Requires Visual Studio 2022 (MSVC)

### Linux
- Build system: CMake with C++14
- Requires GTK3 development libraries

### Web
- Standard Flutter web compilation
- Test in Chrome during development

## Testing Guidelines

- Place widget tests in `test/` directory
- Name test files with `_test.dart` suffix
- Use `flutter_test` package for all tests
- Test file structure should mirror `lib/` structure
- Verify app title is "B站问号榜" in widget tests

## Common Patterns

### Barrel Exports
Each directory has a barrel export file:
```dart
// lib/models/models.dart
export 'leaderboard_item.dart';
export 'user_status.dart';
export 'video_info.dart';
```

### Service Injection
Services are provided at app root and injected via Provider:
```dart
MultiProvider(
  providers: [
    Provider<ApiService>.value(value: apiService),
    ChangeNotifierProvider(create: (_) => LeaderboardProvider(apiService)),
  ],
  // ...
)
```

## Important Conventions

1. **No cursor/copilot rules**: This project has no existing `.cursorrules` or `.github/copilot-instructions.md`
2. **Chinese comments**: Domain-specific Chinese comments are used for Bilibili-related logic
3. **Material 3**: Use Material 3 design system (already configured in theme)
4. **API configuration**: Support custom API endpoints via settings
5. **Altcha verification**: Implement CAPTCHA challenges for voting operations

## Resources

- [Flutter Documentation](https://docs.flutter.dev/)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Provider Package](https://pub.dev/packages/provider)
