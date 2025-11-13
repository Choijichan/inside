import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 앱 테마 제어: 시스템/라이트/다크
enum AppThemeMode { system, light, dark }

class ThemeController extends ChangeNotifier {
  static const _key = 'app_theme_mode';
  AppThemeMode _mode = AppThemeMode.system;
  AppThemeMode get mode => _mode;

  ThemeMode get flutterThemeMode {
    switch (_mode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
      default:
        return ThemeMode.system;
    }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final idx = prefs.getInt(_key) ?? 0;
    _mode = AppThemeMode.values[idx];
    notifyListeners();
  }

  Future<void> setMode(AppThemeMode m) async {
    _mode = m;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, m.index);
  }
}

final darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C83FD),
    brightness: Brightness.dark,
  ),
  useMaterial3: true,
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
);

final lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF7C83FD),
    brightness: Brightness.light,
  ),
  useMaterial3: true,
  inputDecorationTheme: const InputDecorationTheme(
    border: OutlineInputBorder(),
  ),
);

/// ✅ main.dart에서 쓰는 기본 테마
///    `theme: appTheme` 이렇게 연결됨
final ThemeData appTheme = lightTheme;
