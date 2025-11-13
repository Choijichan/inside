import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/di.dart';
import 'core/theme.dart';

// Features
import 'features/diary/diary_provider.dart';
import 'features/schedule/schedule_provider.dart';
import 'features/diary/diary_editor_page.dart';
import 'features/calendar/calendar_page.dart';
import 'features/stats/stats_page.dart';
import 'features/settings/settings_page.dart';

/// 앱 시작부
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDI(); // Drift DB / Repository 등록
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProvider(create: (_) => ScheduleProvider()),
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

/// ⭐ 여기 RootScaffold가 바로 main.dart 안에 존재함
/// 탭 구조 + DiaryEditorPage 이동 처리 포함
class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  /// 캘린더 탭이 기본
  int _index = 0;

  /// 탭에서 사용하는 페이지들
  final _pages = const [
    CalendarPage(),     // index 0
    StatsPage(),        // index 1
    SettingsPage(),     // index 2
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// 탭 전환 시 상태 유지
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined), label: '캘린더'),
          NavigationDestination(
              icon: Icon(Icons.analytics_outlined), label: '통계'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: '설정'),
        ],
        onDestinationSelected: (i) {
          setState(() => _index = i);
        },
      ),

      /// ⭐ 플로팅 버튼 → DiaryEditorPage 열기
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          /// DiaryEditorPage를 push로 띄운다
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DiaryEditorPage()),
          );

          /// DiaryEditorPage의 저장/삭제 후 전달된 값 처리
          if (result == "go_calendar") {
            setState(() => _index = 0); // ⭐ 캘린더 탭으로 이동
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
