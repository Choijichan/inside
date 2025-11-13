import 'package:drift/drift.dart' as drift;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import '../../data/drift/drift_database.dart';
import '../../data/repositories/schedule_repository.dart';

/// 캘린더 월 범위의 일정/일기 요약 + 선택일의 일정 목록 제공
class ScheduleProvider extends ChangeNotifier {
  final ScheduleRepository _repo = GetIt.I<ScheduleRepository>();
  final LocalDatabase _db = GetIt.I<LocalDatabase>();

  DateTime _selectedDate = _normalize(DateTime.now());
  DateTime get selectedDate => _selectedDate;

  List<Schedule> daySchedules = [];
  Map<DateTime, int> scheduleCountByDate = {}; // 날짜별 일정 개수
  Set<DateTime> diaryDates = {};               // 일기 존재 날짜

  StreamSubscription<List<Schedule>>? _rangeSub;

  static DateTime _normalize(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  ScheduleProvider() {
    setSelectedDate(DateTime.now());
    // 초기 월 구독
    final now = DateTime.now();
    setMonthRange(DateTime.utc(now.year, now.month, 1),
                  DateTime.utc(now.year, now.month + 1, 0));
  }

  Future<void> setSelectedDate(DateTime d) async {
    _selectedDate = _normalize(d);
    daySchedules = await _repo.listByDate(_selectedDate);
    notifyListeners();
  }

  /// 월 범위를 구독하여 일정 집계 + 일기 존재 여부 집계
  void setMonthRange(DateTime start, DateTime end) {
    // 안전 처리: 1~말일까지로 정규화
    final s = _normalize(start);
    final e = _normalize(end);

    _rangeSub?.cancel();
    _rangeSub = _repo.watchRange(s, e).listen((list) async {
      // 일정 개수 맵 재생성
      final map = <DateTime, int>{};
      for (final sch in list) {
        final day = _normalize(sch.date);
        map.update(day, (v) => v + 1, ifAbsent: () => 1);
      }
      scheduleCountByDate = map;

      // 일기 존재 날짜 집계 (DB 직접 조회 - 코드생성 불필요)
      final diaryRows = await (_db.select(_db.diaries)
            ..where((t) => t.date.isBetweenValues(s, e)))
          .get();
      diaryDates = diaryRows.map((d) => _normalize(d.date)).toSet();

      // 선택일의 최신 일정 목록도 갱신
      daySchedules = await _repo.listByDate(_selectedDate);

      notifyListeners();
    });
  }

  Future<int> addSchedule({
    required DateTime date,
    required int startMin,
    required int endMin,
    required String title,
    String? memo,
  }) async {
    final id = await _repo.insert(
      date: date, startMin: startMin, endMin: endMin, title: title, memo: memo,
    );
    await setSelectedDate(date);
    return id;
  }

  Future<void> updateSchedule({
    required int id,
    required DateTime date,
    required int startMin,
    required int endMin,
    required String title,
    String? memo,
  }) async {
    await _repo.update(
      id: id, date: date, startMin: startMin, endMin: endMin, title: title, memo: memo,
    );
    await setSelectedDate(date);
  }

  Future<void> deleteSchedule(int id) async {
    await _repo.delete(id);
    await setSelectedDate(_selectedDate);
  }

  @override
  void dispose() {
    _rangeSub?.cancel();
    super.dispose();
  }
}
