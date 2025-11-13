import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import '../diary/diary_provider.dart';
import '../schedule/schedule_provider.dart';
import '../schedule/schedule_editor.dart';
import '../schedule/time_utils.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime _focusedDay = DateTime.now();
  DateTime _firstDayOfMonth(DateTime d) => DateTime.utc(d.year, d.month, 1);
  DateTime _lastDayOfMonth(DateTime d) => DateTime.utc(d.year, d.month + 1, 0);

  @override
  void initState() {
    super.initState();
    // ScheduleProvider를 초기화해 월 범위를 구독
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<ScheduleProvider>();
      sp.setMonthRange(_firstDayOfMonth(_focusedDay), _lastDayOfMonth(_focusedDay));
      sp.setSelectedDate(_focusedDay);
      context.read<DiaryProvider>().setDate(_focusedDay);
    });
  }

  @override
  Widget build(BuildContext context) {
    final diary = context.watch<DiaryProvider>();
    final sched = context.watch<ScheduleProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2010, 1, 1),
            lastDay: DateTime.utc(2035, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) =>
                d.year == sched.selectedDate.year &&
                d.month == sched.selectedDate.month &&
                d.day == sched.selectedDate.day,
            onDaySelected: (sel, foc) {
              sched.setSelectedDate(sel);
              diary.setDate(sel);
              setState(() => _focusedDay = foc);
            },
            onPageChanged: (foc) {
              setState(() => _focusedDay = foc);
              sched.setMonthRange(_firstDayOfMonth(foc), _lastDayOfMonth(foc));
            },
            headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                final d = DateTime.utc(day.year, day.month, day.day);
                final hasDiary = sched.diaryDates.contains(d);
                final count = sched.scheduleCountByDate[d] ?? 0;
                if (!hasDiary && count == 0) return null;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (hasDiary)
                        Container(width: 6, height: 6, decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        )),
                      if (count > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            color: Theme.of(context).colorScheme.secondaryContainer,
                          ),
                          child: Text('$count', style: const TextStyle(fontSize: 10)),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text('선택: ${sched.selectedDate.toIso8601String().substring(0,10)}', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                FilledButton.icon(
                  onPressed: () => openScheduleDialog(context, date: sched.selectedDate),
                  icon: const Icon(Icons.add),
                  label: const Text('일정 추가'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.separated(
              itemCount: sched.daySchedules.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final s = sched.daySchedules[i];
                return ListTile(
                  leading: const Icon(Icons.event_note),
                  title: Text(s.title),
                  subtitle: Text('${mmToHHmm(s.startMin)} ~ ${mmToHHmm(s.endMin)}${s.memo == null ? '' : ' · ${s.memo}'}'),
                  onTap: () => openScheduleDialog(context,
                    id: s.id,
                    date: s.date,
                    startMin: s.startMin,
                    endMin: s.endMin,
                    title: s.title,
                    memo: s.memo ?? '',
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
