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

  runApp(BiliQmlApp(storageService: storageService, apiService: apiService));
}

class BiliQmlApp extends StatelessWidget {
  final StorageService storageService;
  final ApiService apiService;

  const BiliQmlApp({
    super.key,
    required this.storageService,
    required this.apiService,
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
        ChangeNotifierProvider(create: (_) => LeaderboardProvider(apiService)),
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
