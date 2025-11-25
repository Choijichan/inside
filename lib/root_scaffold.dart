import 'package:flutter/material.dart';

import 'features/diary/diary_editor_page.dart';
import 'features/calendar/calendar_page.dart';
import 'features/stats/stats_page.dart';
import 'features/settings/settings_page.dart';

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 1; // 기본 탭: 캘린더

  final _pages = const [
    DiaryEditorPage(),  // 작성
    CalendarPage(),     // 캘린더
    StatsPage(),        // 통계
    SettingsPage(),     // 설정
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            label: '다이어리',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            label: '통계',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            label: '설정',
          ),
        ],
        onDestinationSelected: (i) => setState(() => _index = i),
      ),

      /// 빠른 일기 작성 버튼
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() => _index = 0); // 다이어리 탭으로 이동
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
