// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';
import 'package:bili_qml_app/main.dart';
import 'package:bili_qml_app/services/services.dart';

void main() {
  testWidgets('App builds successfully', (WidgetTester tester) async {
    // 初始化存储服务
    final storageService = StorageService();

    // 初始化 API 服务
    final apiService = ApiService();

    // 初始化收藏和历史服务
    final favoritesService = FavoritesService(storageService);
    final historyService = HistoryService(storageService);

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      BiliQmlApp(
        storageService: storageService,
        apiService: apiService,
        favoritesService: favoritesService,
        historyService: historyService,
      ),
    );

    // 验证应用标题显示
    expect(find.text('B站问号榜'), findsOneWidget);
  });
}
