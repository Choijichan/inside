import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di.dart';
import 'core/theme.dart';
import 'features/diary/diary_editor_page.dart';
import 'features/calendar/calendar_page.dart';
import 'features/stats/stats_page.dart';
import 'features/settings/settings_page.dart';
import 'features/diary/diary_provider.dart';

/// Step 2 - 앱 스켈레톤: BottomNav, 라우팅, DI 초기화
/// - Step 1에서 만든 Drift DB(LocalDatabase) 및 Repository를 DI에 등록
/// - 아직 고급 UI/기능(이미지 첨부, 알림 등)은 미구현 상태
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDI(); // GetIt에 DB/Repository 등록
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
      ],
      child: MaterialApp(
        title: 'Diary + Calendar',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        home: const RootScaffold(),
      ),
    );
  }
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 1; // 기본 탭: 캘린더
  final _pages = const [
    DiaryEditorPage(),
    CalendarPage(),
    StatsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.book_outlined), label: '다이어리'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: '캘린더'),
          NavigationDestination(icon: Icon(Icons.analytics_outlined), label: '통계'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: '설정'),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // 빠른 기록: 오늘 일기 탭으로 전환
          setState(() => _index = 0);
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
