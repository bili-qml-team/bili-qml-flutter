# Agent Guidelines for bili-qml-flutter

Guidelines for agentic coding in the B站问号榜 Flutter app.

## Project Overview
- **Type**: Multi-platform Flutter app (Android/iOS/Windows/Linux/Web)
- **Purpose**: Bilibili leaderboard client with voting
- **Language**: Dart 3.10.7+
- **Framework**: Flutter 3.38.7+
- **State**: Provider pattern
- **Architecture**: Clean (Models/Services/Providers/UI)
## Commands
### Setup
```bash
flutter pub get
```
### Run (debug)
```bash
flutter run
flutter run -d windows
flutter run -d chrome
flutter run -d android
flutter run -d linux
```
### Build
```bash
flutter build apk
flutter build appbundle
flutter build windows
flutter build linux
flutter build web
flutter build ios
flutter build apk --release
flutter build windows --profile
```
### Lint / Format
```bash
flutter analyze
dart format lib/ test/
dart format --output=none --set-exit-if-changed lib/ test/
```
### Testing
```bash
flutter test
flutter test test/widget_test.dart
flutter test test/widget_test.dart -n "test name"
flutter test --coverage
flutter test --verbose
```
### Clean
```bash
flutter clean
flutter clean && flutter pub get
```
## Project Structure
```
lib/
├── config/
├── models/
├── providers/
├── screens/
├── services/
├── theme/
├── widgets/
└── main.dart
```
## Code Style Guidelines
### General
- Follow Flutter style + `flutter_lints`.
- Prefer readability; add comments only for non-obvious logic.
- Chinese comments are fine for Bilibili domain logic.
### Imports
```dart
// 1. Dart SDK
import 'dart:convert';
import 'package:flutter/material.dart';

// 2. Packages
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

// 3. Local (use barrel exports)
import '../models/models.dart';
import '../services/services.dart';
```
- Group by type with blank lines.
- Prefer barrel exports (`models.dart`, `services.dart`, etc.).
- Alias imports when needed.
### Formatting
- Use `dart format` (80 column default).
- Use trailing commas for cleaner diffs.
- Single quotes unless interpolation/escaping needs double.
### Naming
- Classes/enums: PascalCase.
- Files: snake_case.
- Variables/functions: camelCase.
- Private members: leading underscore.
- Constants: lowerCamelCase.
### Types
- Type all class fields and public members.
- Use `final` when immutable; `var` only for obvious locals.
- Use nullable types explicitly (`String?`).
- Prefer `required` for non-null params.
### Error Handling & Logging
- Use try/catch around async IO.
- Surface user-facing error strings in providers.
- Prefer custom exceptions for domain errors.
- Use `debugPrint`; avoid `print` in production.
### Async/Await
- Use `async`/`await` (no `.then`).
- Mark async only when needed.
- Use `Future.wait` for parallel fetches.
### Provider Pattern
- Extend `ChangeNotifier`.
- Keep state private with public getters.
- Call `notifyListeners()` after state mutation.
- Inject services via constructor.
### JSON
- Use factory constructors for deserialization.
- Use explicit casts (`as String`).
- Handle nullables carefully.
### Widgets
- Prefer `const` constructors.
- Use `StatelessWidget` unless local state is required.
- Extract complex widget trees into widgets/methods.
- Keep build methods readable and short.
## Testing Conventions
- Tests live in `test/` and mirror `lib/` layout.
- Test files end with `_test.dart`.
- Use `flutter_test`.
- Ensure app title is "B站问号榜" in widget tests.
## Platform Notes
- Android: Gradle (Kotlin DSL); configure `android/key.properties`.
- Windows: CMake, MSVC 2022.
- Linux: CMake, GTK3 dev libs.
- Web: validate in Chrome.
## Repository Conventions
- Material 3 theming is configured; keep it consistent.
- API base URL can be customized in settings.
- Altcha verification is required for voting flows.
- Barrel export files exist per directory.
## Cursor/Copilot Rules
- No `.cursorrules`, `.cursor/rules/`, or `.github/copilot-instructions.md` found.
