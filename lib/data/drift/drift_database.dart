import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'drift_database.g.dart';

// Diaries 테이블
class Diaries extends Table {
  IntColumn get id => integer().autoIncrement()();

  // UTC 자정
  DateTimeColumn get date => dateTime()();

  IntColumn get emotion => integer()(); // 1~5 감정 값
  TextColumn get title => text()();
  TextColumn get content => text()();

  // 이미지 또는 영상 (Firebase Storage URL 또는 로컬 경로)
  TextColumn get imagePath => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
}

// Schedules 테이블
class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();

  // UTC 자정 날짜
  DateTimeColumn get date => dateTime()();

  // 자정 기준 시작/끝 분 (0~1440)
  IntColumn get startMin => integer()();
  IntColumn get endMin => integer()();

  TextColumn get title => text()();
  TextColumn get memo => text().nullable()();

  // Drift는 snake_case로 컬럼을 생성함:
  // startMin → start_min
  // endMin   → end_min
  @override
  List<String> get customConstraints => [
        'CHECK (start_min >= 0 AND start_min <= 1440)',
        'CHECK (end_min >= 0 AND end_min <= 1440)',
      ];
}

// Database 클래스
@DriftDatabase(tables: [Diaries, Schedules])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // Diaries 기능

  Future<Diary?> getDiary(DateTime date) {
    final n = DateTime.utc(date.year, date.month, date.day);
    return (select(diaries)..where((t) => t.date.equals(n))).getSingleOrNull();
  }

  Stream<Diary?> watchDiary(DateTime date) {
    final n = DateTime.utc(date.year, date.month, date.day);
    return (select(diaries)..where((t) => t.date.equals(n))).watchSingleOrNull();
  }

  Future<void> upsertDiary({
    required DateTime normalizedDate,
    required int emotion,
    required String title,
    required String content,
    String? imagePath,
  }) async {
    final comp = DiariesCompanion(
      date: Value(normalizedDate),
      emotion: Value(emotion),
      title: Value(title),
      content: Value(content),
      imagePath: imagePath == null ? const Value.absent() : Value(imagePath),
      updatedAt: Value(DateTime.now()),
    );

    await into(diaries).insertOnConflictUpdate(comp);
  }

  Future<int> deleteDiary(DateTime date) {
    final n = DateTime.utc(date.year, date.month, date.day);
    return (delete(diaries)..where((t) => t.date.equals(n))).go();
  }

  // Schedule 기능 (기존)

  // 특정 날짜 일정 스트림 (UI에서 watch용)
  Stream<List<Schedule>> watchSchedules(DateTime date) {
    final n = DateTime.utc(date.year, date.month, date.day);
    return (select(schedules)..where((t) => t.date.equals(n))).watch();
  }

  // id 있으면 update, 없으면 insert 형태의 upsert
  Future<void> upsertSchedule({
    required int? id,
    required DateTime date,
    required int startMin,
    required int endMin,
    required String title,
    String? memo,
  }) async {
    final comp = SchedulesCompanion(
      id: id == null ? const Value.absent() : Value(id),
      date: Value(DateTime.utc(date.year, date.month, date.day)),
      startMin: Value(startMin),
      endMin: Value(endMin),
      title: Value(title),
      memo: memo == null ? const Value.absent() : Value(memo),
    );

    await into(schedules).insertOnConflictUpdate(comp);
  }

  // id로 일정 삭제
  Future<int> deleteSchedule(int id) {
    return (delete(schedules)..where((t) => t.id.equals(id))).go();
  }

  // Schedule 기능 (Repository에서 사용하는 헬퍼들)

  // 특정 날짜의 일정 리스트
  Future<List<Schedule>> listSchedules(DateTime date) {
    final n = DateTime.utc(date.year, date.month, date.day);
    return (select(schedules)..where((t) => t.date.equals(n))).get();
  }

  // 날짜 구간으로 일정 스트림 조회 (예: 캘린더 월간 범위)
  Stream<List<Schedule>> watchSchedulesInRange(DateTime start, DateTime end) {
    final s = DateTime.utc(start.year, start.month, start.day);
    final e = DateTime.utc(end.year, end.month, end.day);

    return (select(schedules)
          ..where((t) => t.date.isBetweenValues(s, e))
          ..orderBy([
            (t) => OrderingTerm.asc(t.date),
            (t) => OrderingTerm.asc(t.startMin),
          ]))
        .watch();
  }

  // 일정 추가 (Repository에서 SchedulesCompanion 만들어서 넘김)
  Future<int> insertSchedule(SchedulesCompanion comp) {
    return into(schedules).insert(comp);
  }

  // 일정 수정 (id 기준으로 write)
  Future<bool> updateSchedule(SchedulesCompanion comp) async {
    final idValue = comp.id.value;
    final affected = await (update(schedules)
          ..where((t) => t.id.equals(idValue)))
        .write(comp);
    return affected > 0;
  }
}

// SQLite 파일(app.sqlite) 생성 경로
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
