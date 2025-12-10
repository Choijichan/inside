import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// intl 날짜 로케일 (TableCalendar에서 locale: 'ko_KR' 쓰기 위함)
import 'package:intl/date_symbol_data_local.dart';

// DI & Theme & Notification
import 'core/di.dart';
import 'core/theme.dart';
import 'core/notification_service.dart';

// PIN 잠금 관련
import 'core/pin_lock.dart';
import 'core/pin_gate.dart';

// Providers
import 'features/diary/diary_provider.dart';
import 'features/schedule/schedule_provider.dart';

// 앱 시작 지점
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TableCalendar 등에서 'ko_KR' 로케일을 쓰기 위한 초기화
  await initializeDateFormatting('ko_KR', null);

  // 1) Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 2) Drift DB / Repository 등록 (GetIt)
  await setupDI();

  // 3) 로컬 알림 초기화
  await NotificationService().init();

  // 4) 앱 실행
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // 테마 컨트롤러
        ChangeNotifierProvider(
          create: (_) => ThemeController()..load(),
        ),

        // Diary 기능 Provider
        ChangeNotifierProvider(
          create: (_) => DiaryProvider(),
        ),

        // Schedule 기능 Provider
        ChangeNotifierProvider(
          create: (_) => ScheduleProvider(),
        ),

        // PIN 잠금 컨트롤러
        ChangeNotifierProvider(
          create: (_) => PinLockController(),
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp(
            title: 'Diary + Calendar',
            debugShowCheckedModeBanner: false,
            theme: lightTheme,
            darkTheme: darkTheme,
            themeMode: themeController.flutterThemeMode,

            // 앱 시작 시 PIN 잠금 / 바로 진입 분기
            home: const PinGate(),
          );
        },
      ),
    );
  }
}
