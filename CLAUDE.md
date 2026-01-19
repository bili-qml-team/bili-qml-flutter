# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

B站问号榜 (Bilibili Q-Mark List) - A Flutter client for tracking and voting on "abstract" (weird/funny) videos on Bilibili. Supports Android, Windows, Linux, and Web platforms.

## Build & Run Commands

```bash
# Install dependencies
flutter pub get

# Run development
flutter run -d windows  # Windows
flutter run -d linux    # Linux
flutter run -d android  # Android
flutter run -d chrome   # Web

# Build release
flutter build windows --release  # Output: build/windows/runner/Release/
flutter build apk --release      # Output: build/app/outputs/flutter-apk/
flutter build linux --release    # Output: build/linux/x64/release/bundle/
flutter build web --release      # Output: build/web/

# Clean and rebuild
flutter clean && flutter pub get
```

## Architecture

### Directory Structure

```
lib/
├── config/       # Constants, API configs, enums (LeaderboardRange)
├── models/       # Data classes (LeaderboardItem, FavoriteItem, VideoInfo, FilterCriteria)
├── services/     # Business logic & API (ApiService, StorageService, filter/)
├── providers/    # State management (ChangeNotifier-based providers)
├── screens/      # UI pages (HomeScreen, VideoScreen, SettingsScreen, etc.)
├── widgets/      # Reusable components (VideoCard, VoteFab, AltchaDialog)
├── theme/        # Material 3 theming (light/dark modes)
└── main.dart     # Entry point, MultiProvider setup
```

### State Management: Provider Pattern

Providers extend `ChangeNotifier` and are set up via `MultiProvider` in main.dart:
- **LeaderboardProvider** - Leaderboard data, pagination (pages 1-10), filtering
- **FavoritesProvider** - Local favorites CRUD, grouped by date
- **HistoryProvider** - Watch history management
- **ThemeProvider** - Light/dark theme persistence
- **SettingsProvider** - API endpoint, user ID, preferences

### FilterableProvider Base Class

`lib/providers/base/filterable_provider.dart` provides a template for filterable data:
```dart
// Get filtered items
List<T> get items => _filterEngine.filter(_rawItems, _criteria);

// Update filters
void updateFilter(FilterCriteria criteria)
void updateFilterPartial({String? keyword, String? upName, ...})
void clearFilters()
```

### Filtering Engine (Strategy Pattern)

`lib/services/filter/` implements composable filters:
- **FilterEngine<T>** - Composes strategies with AND logic
- **FilterStrategy<T>** - Interface for filter implementations
- Strategies: TitleFilterStrategy, UpNameFilterStrategy, ViewCountFilterStrategy, DanmakuCountFilterStrategy

### API Service

`lib/services/api_service.dart` handles all network requests:
- Custom API base URL support (default: `https://bili-qml.bydfk.com/api`)
- Bilibili video info fetching (`https://api.bilibili.com/x/web-interface/view`)
- Altcha CAPTCHA integration for voting
- Cache-busting via `_t` timestamp parameter

Key endpoints: `/leaderboard`, `/vote`, `/unvote`, `/status`, `/altcha/challenge`

### Data Flow

```
ApiService → Response Models → Providers (cached state) → UI (screens/widgets)
```

Leaderboard data is minimal from API (BVID + votes), then enriched asynchronously from Bilibili API.

## Key Patterns

- **Barrel exports**: Each module has an export file (e.g., `models.dart`, `services.dart`) for clean imports
- **Immutable models**: `const` constructors, `copyWith()`, `fromJson()` factories
- **Consumer vs context.read()**: Use `Consumer<T>` for reactive UI, `context.read<T>()` for one-time operations
- **Progressive loading**: Leaderboard updates UI every 3 items while fetching video details

## Configuration

`lib/config/constants.dart` contains:
- API base URLs
- `LeaderboardRange` enum (realtime, daily, weekly, monthly)
- Storage keys for SharedPreferences
