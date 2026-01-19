import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/constants.dart';
import 'providers/providers.dart';
import 'screens/screens.dart';
import 'services/services.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化存储服务
  final storageService = StorageService();
  await storageService.init();

  // 初始化 API 服务
  final savedEndpoint = storageService.getApiEndpoint();
  final apiService = ApiService(
    apiBase: savedEndpoint ?? ApiConfig.defaultApiBase,
  );

  // 初始化收藏和历史服务
  final favoritesService = FavoritesService(storageService);
  final historyService = HistoryService(storageService);

  runApp(
    BiliQmlApp(
      storageService: storageService,
      apiService: apiService,
      favoritesService: favoritesService,
      historyService: historyService,
    ),
  );
}

class BiliQmlApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;
  final FavoritesService favoritesService;
  final HistoryService historyService;

  const BiliQmlApp({
    super.key,
    required this.storageService,
    required this.apiService,
    required this.favoritesService,
    required this.historyService,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 服务层
        Provider<StorageService>.value(value: storageService),
        Provider<ApiService>.value(value: apiService),

        // 状态管理
        ChangeNotifierProvider(create: (_) => ThemeProvider(storageService)),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider(storageService, apiService),
        ),
        ChangeNotifierProvider(
          create: (_) => LeaderboardProvider(apiService, storageService.prefs),
        ),
        ChangeNotifierProvider(
          create: (_) => FavoritesProvider(favoritesService)..init(),
        ),
        ChangeNotifierProvider(
          create: (_) => HistoryProvider(historyService)..init(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'B站问号榜',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
