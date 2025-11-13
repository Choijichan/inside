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
  await setupDI();
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

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  final _pages = const [
    CalendarPage(),
    StatsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: _pages,
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            label: '통계',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: '설정',
          ),
        ],
        onDestinationSelected: (i) {
          setState(() => _index = i);
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DiaryEditorPage()),
          );

          /// DiaryEditorPage에서 pop("go_calendar") 받은 경우
          if (result == "go_calendar") {
            setState(() => _index = 0);
          }
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
