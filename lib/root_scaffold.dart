import 'package:flutter/material.dart';

import 'features/diary/diary_list_page.dart';
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

  late final List<Widget> _pages = [
    const DiaryListPage(),
    const CalendarPage(),
    const StatsPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],

      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: '다이어리',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: '캘린더',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: '통계',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '설정',
          ),
        ],
      ),

      /// 다이어리 작성 버튼 (항상 가운데)
      floatingActionButton: FloatingActionButton(
        heroTag: 'rootDiaryFab', // ✅ Hero 태그 직접 지정 (중복 방지)
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DiaryEditorPage(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
