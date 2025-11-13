import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../diary/diary_provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) =>
                d.year == provider.selectedDate.year &&
                d.month == provider.selectedDate.month &&
                d.day == provider.selectedDate.day,
            onDaySelected: (sel, foc) {
              provider.setDate(sel);
              setState(() => _focusedDay = foc);
            },
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),
          const SizedBox(height: 12),
          const Text('이 날의 일정/일기는 다음 단계에서 표시됩니다.'),
        ],
      ),
    );
  }
}
