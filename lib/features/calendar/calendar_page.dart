import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:diary_calendar_app/data/drift/drift_database.dart';

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
  late DateTime _focusedDay;
  late DateTime _selectedDay;
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _focusedDay = DateTime.utc(now.year, now.month, now.day);
    _selectedDay = _focusedDay;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 최초 진입 시 오늘 날짜로 Provider들 동기화
    final sched = context.read<ScheduleProvider>();
    final diary = context.read<DiaryProvider>();

    sched.setSelectedDate(_selectedDay);
    final first = DateTime.utc(_focusedDay.year, _focusedDay.month, 1);
    final last = DateTime.utc(_focusedDay.year, _focusedDay.month + 1, 0);
    sched.setMonthRange(first, last);

    diary.setDate(_selectedDay);
  }

  DateTime _normalize(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  String _monthLabel(DateTime d) => '${d.month}월';

  String _selectedDateLabel(DateTime d) {
    final day = d.day.toString();
    final ym = DateFormat('MM월 yyyy').format(d);
    return '$day  $ym';
  }

  @override
  Widget build(BuildContext context) {
    final sched = context.watch<ScheduleProvider>();
    final diary = context.watch<DiaryProvider>();

    final selectedDate = sched.selectedDate; // 기준 날짜
    final schedules = [...sched.daySchedules]
      ..sort((a, b) => a.startMin.compareTo(b.startMin));
    final currentDiary = diary.current;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 상단: 월 표시 + 캘린더
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _monthLabel(_focusedDay),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime.utc(
                              _focusedDay.year,
                              _focusedDay.month - 1,
                              1,
                            );
                          });
                          final first = DateTime.utc(
                              _focusedDay.year, _focusedDay.month, 1);
                          final last = DateTime.utc(
                              _focusedDay.year, _focusedDay.month + 1, 0);
                          context
                              .read<ScheduleProvider>()
                              .setMonthRange(first, last);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _focusedDay = DateTime.utc(
                              _focusedDay.year,
                              _focusedDay.month + 1,
                              1,
                            );
                          });
                          final first = DateTime.utc(
                              _focusedDay.year, _focusedDay.month, 1);
                          final last = DateTime.utc(
                              _focusedDay.year, _focusedDay.month + 1, 0);
                          context
                              .read<ScheduleProvider>()
                              .setMonthRange(first, last);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            _buildCalendar(context),

            const SizedBox(height: 8),

            // 하단: 선택한 날짜의 다이어리 + 일정
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 날짜 라벨
                    Text(
                      _selectedDateLabel(selectedDate),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),

                    // 다이어리 섹션 (항상 위)
                    _buildDiarySection(context, currentDiary),

                    const SizedBox(height: 16),
                    Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .outline
                          .withOpacity(0.4),
                    ),
                    const SizedBox(height: 8),

                    // 일정 섹션 (다이어리 아래)
                    Expanded(
                      child: _buildScheduleSection(
                        context,
                        selectedDate,
                        schedules: schedules,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

      // 여기 heroTag 추가해서 RootScaffold의 FAB와 구분
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendarFab',
        onPressed: () async {
          // 선택한 날짜 기준으로 새 일정 추가
          await openScheduleDialog(
            context,
            date: sched.selectedDate,
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCalendar(BuildContext context) {
    final sched = context.watch<ScheduleProvider>();

    return TableCalendar(
      locale: 'ko_KR',
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2100, 12, 31),
      focusedDay: _focusedDay,
      calendarFormat: _format,
      headerVisible: false,
      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
      onDaySelected: (selected, focused) {
        setState(() {
          _selectedDay = _normalize(selected);
          _focusedDay = focused;
        });

        // 선택한 날짜로 Provider 상태 동기화
        context.read<ScheduleProvider>().setSelectedDate(_selectedDay);
        context.read<DiaryProvider>().setDate(_selectedDay);
      },
      onPageChanged: (focused) {
        _focusedDay = focused;
        final first = DateTime.utc(focused.year, focused.month, 1);
        final last = DateTime.utc(focused.year, focused.month + 1, 0);
        context.read<ScheduleProvider>().setMonthRange(first, last);
      },
      onFormatChanged: (format) {
        setState(() => _format = format);
      },
      calendarStyle: const CalendarStyle(
        todayDecoration: BoxDecoration(
          shape: BoxShape.circle,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          final sp = context.watch<ScheduleProvider>();
          final d = _normalize(day);
          final count = sp.scheduleCountByDate[d] ?? 0;
          final hasDiary = sp.diaryDates.contains(d);

          if (count == 0 && !hasDiary) return null;

          return Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasDiary)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                if (count > 0) ...[
                  const SizedBox(width: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  // 상단 다이어리 섹션
  Widget _buildDiarySection(BuildContext context, Diary? diary) {
    if (diary == null) {
      return Text(
        '이 날짜에는 작성한 다이어리가 없습니다.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '다이어리',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        Text(
          diary.title.isEmpty ? '(제목 없음)' : diary.title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 4),
        Text(
          diary.content,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  // 하단 일정 섹션
  Widget _buildScheduleSection(
    BuildContext context,
    DateTime selectedDate, {
    required List<Schedule> schedules,
  }) {
    if (schedules.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Text(
          '등록된 일정이 없습니다.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).hintColor,
              ),
        ),
      );
    }

    return ListView.separated(
      itemCount: schedules.length,
      separatorBuilder: (_, __) => Divider(
        height: 16,
        color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
      ),
      itemBuilder: (context, index) {
        final s = schedules[index];

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 시간
            SizedBox(
              width: 70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mmToHHmm(s.startMin),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mmToHHmm(s.endMin),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // 제목 + 메모
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () async {
                  await openScheduleDialog(
                    context,
                    id: s.id,
                    date: s.date,
                    startMin: s.startMin,
                    endMin: s.endMin,
                    title: s.title,
                    memo: s.memo ?? '',
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (s.memo != null && s.memo!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          s.memo!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
