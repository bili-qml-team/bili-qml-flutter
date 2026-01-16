import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'colors.dart';
import 'dart:io';

/// 应用主题配置
class AppTheme {
  /// 浅色主题
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: !kIsWeb && Platform.isWindows ? 'Microsoft YaHei' : null,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.biliBlue,
        onPrimary: Colors.white,
        secondary: AppColors.biliBlue,
        surface: AppColors.lightCardBackground,
        onSurface: AppColors.lightTextPrimary,
        surfaceContainerHighest: AppColors.lightBackground,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      cardTheme: CardThemeData(
        color: AppColors.lightCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightCardBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.biliBlue,
        unselectedLabelColor: AppColors.lightTextSecondary,
        indicatorColor: AppColors.biliBlue,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.biliBlue,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.lightTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: AppColors.lightTextPrimary),
        bodyMedium: TextStyle(color: AppColors.lightTextSecondary),
        bodySmall: TextStyle(color: AppColors.lightTextTertiary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.lightBackground,
        labelStyle: const TextStyle(color: AppColors.lightTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  /// 深色主题
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: !kIsWeb && Platform.isWindows ? 'Microsoft YaHei' : null,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.biliBlue,
        onPrimary: Colors.white,
        secondary: AppColors.biliBlue,
        surface: AppColors.darkCardBackground,
        onSurface: AppColors.darkTextPrimary,
        surfaceContainerHighest: AppColors.darkBackground,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      cardTheme: CardThemeData(
        color: AppColors.darkCardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkCardBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: AppColors.biliBlue,
        unselectedLabelColor: AppColors.darkTextSecondary,
        indicatorColor: AppColors.biliBlue,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.biliBlue,
        foregroundColor: Colors.white,
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.bold,
        ),
        titleLarge: TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: AppColors.darkTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(color: AppColors.darkTextPrimary),
        bodyMedium: TextStyle(color: AppColors.darkTextSecondary),
        bodySmall: TextStyle(color: AppColors.darkTextTertiary),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.darkBackground,
        labelStyle: const TextStyle(color: AppColors.darkTextPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
