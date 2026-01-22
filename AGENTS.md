# Agent Guidelines for bili-qml-flutter

Guidelines for agentic coding in the B站问号榜 Flutter app.

## Project Overview
- **Type**: Multi-platform Flutter app (Android/Windows/Linux/Web; iOS untested)
- **Purpose**: Bilibili leaderboard client with voting
- **Language**: Dart 3.10.7+
- **Framework**: Flutter 3.10.0+ (repo uses flutter_lints)
- **State**: Provider pattern (ChangeNotifier)
- **Architecture**: Models / Services / Providers / UI (screens/widgets)

## Commands

### Setup
```bash
flutter pub get
```

### Run (debug)
```bash
flutter run
flutter run -d windows
flutter run -d linux
flutter run -d android
flutter run -d chrome
flutter run -d ios
```

### Build (release)
```bash
flutter build windows --release
flutter build apk --release
flutter build appbundle --release
flutter build linux --release
flutter build web --release
flutter build ios --release
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
├── config/       # Constants, API configs, enums
├── models/       # Data classes (LeaderboardItem, FavoriteItem, VideoInfo, FilterCriteria)
├── services/     # Business logic & API (ApiService, StorageService, filter/)
├── providers/    # State management (ChangeNotifier-based providers)
├── screens/      # UI pages (HomeScreen, VideoScreen, SettingsScreen, etc.)
├── widgets/      # Reusable components (VideoCard, VoteFab, AltchaDialog)
├── theme/        # Material 3 theming (light/dark modes)
└── main.dart     # Entry point, MultiProvider setup
```

## Code Style Guidelines

### General
- Follow Flutter style + `flutter_lints` (see `analysis_options.yaml`).
- Prefer readability; add comments only for non-obvious logic.
- Chinese comments are acceptable for Bilibili-specific domain logic.

### Imports
Order and group imports with blank lines:
```dart
// 1. Dart SDK
import 'dart:convert';

// 2. Packages
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 3. Local (use barrel exports)
import '../models/models.dart';
import '../services/services.dart';
```
- Prefer barrel exports (`models.dart`, `services.dart`, `providers.dart`, `widgets.dart`, `screens.dart`).
- Alias imports when needed (e.g., `import 'package:http/http.dart' as http;`).

### Formatting
- Use `dart format` (default 80-column style).
- Use trailing commas for multi-line argument lists.
- Prefer single quotes unless interpolation/escaping requires double.

### Naming
- Classes/enums: PascalCase.
- Files: snake_case.
- Variables/functions: camelCase.
- Private members: leading underscore.
- Constants: lowerCamelCase.

### Types & Null Safety
- Type all class fields and public members explicitly.
- Use `final` when immutable; `var` only for obvious locals.
- Use nullable types explicitly (`String?`).
- Prefer `required` for non-null parameters.

### Error Handling & Logging
- Use try/catch around async I/O and network requests.
- Surface user-facing error strings in providers where appropriate.
- Prefer custom exceptions for domain errors.
- Use `debugPrint` for logging; avoid `print` in production code.

### Async/Await
- Prefer `async`/`await` (avoid `.then`).
- Mark async only when needed.
- Use `Future.wait` for parallel fetches.

### Models & JSON
- Use `final` fields and `const` constructors when possible.
- Use `factory ...fromJson` for deserialization.
- Use explicit casts (`as String`, `as int`), handle nullables carefully.
- Keep models immutable; provide `copyWith` where appropriate.

### Provider Pattern
- Extend `ChangeNotifier`.
- Keep state private with public getters.
- Call `notifyListeners()` after state mutation.
- Inject services via constructor.
- Use `Consumer<T>` for reactive UI; `context.read<T>()` for one-off actions.

### Widgets
- Prefer `const` constructors.
- Use `StatelessWidget` unless local state is required.
- Extract complex widget trees into smaller widgets/methods.
- Keep build methods readable and short.
- Use Material 3 theming and existing theme/colors consistently.

### UI/UX
- Preserve existing layout/visual patterns; reuse `AppColors` and theme styles.
- Keep spacing/sizing consistent with nearby widgets.

## Testing Conventions
- Tests live in `test/` and mirror `lib/` layout.
- Test files end with `_test.dart`.
- Use `flutter_test`.
- App title is "B站问号榜" in widget tests.

## Platform Notes
- Android: Gradle (Kotlin DSL); configure `android/key.properties` for signing.
- Windows: CMake, MSVC 2022.
- Linux: CMake, GTK3 dev libs.
- Web: validate in Chrome; CORS proxy may be required for B站 API.

## Repository Conventions
- Material 3 theming is configured; keep it consistent.
- API base URL can be customized in settings.
- Altcha verification is required for voting flows.
- Leaderboard data is loaded progressively and enriched with Bilibili API details.

## Cursor/Copilot Rules
- No `.cursorrules`, `.cursor/rules/`, or `.github/copilot-instructions.md` found in this repo.
