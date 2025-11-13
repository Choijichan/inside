/// Drift database for Calendar + Diary app
/// -------------------------------------------------------------
/// - Tables:
///   * Diaries    : 1일 1개 일기(감정/제목/본문/이미지 경로)
///   * Schedules  : 날짜별 일정(시작/종료 분 단위)
/// - 날짜 컬럼은 'UTC 자정'으로 정규화(yyyy-mm-dd 기준 검색이 쉬움)
/// - `insertOnConflictUpdate`를 이용한 Upsert 지원
/// - 이미지 파일은 디바이스에 저장하고 DB에는 경로 문자열만 저장
/// -------------------------------------------------------------
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'drift_database.g.dart';

// =============== Tables ===============

/// 하루에 일기 1개(프라이머리 키: date).
class Diaries extends Table {
  /// UTC 자정으로 정규화된 날짜(PrimaryKey)
  DateTimeColumn get date => dateTime()();

  /// 감정(0~4) - 2는 보통(중립)
  IntColumn get emotion => integer().withDefault(const Constant(2))();

  /// 제목/본문 - 기본값은 빈 문자열
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get content => text().withDefault(const Constant(''))();

  /// 선택 이미지의 로컬 경로(없을 수 있음)
  TextColumn get imagePath => text().nullable()();

  /// 생성/수정 시각
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {date};
}

/// 일정(여러 개 가능)
class Schedules extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// UTC 자정으로 정규화된 날짜
  DateTimeColumn get date => dateTime()();

  /// 자정으로부터의 분(0~1440), 시간 계산이 쉬움
  IntColumn get startMin => integer()();
  IntColumn get endMin => integer()();

  TextColumn get title => text()();
  TextColumn get memo => text().nullable()();

  @override
  List<String> get customConstraints => [
    'CHECK (startMin >= 0 AND startMin <= 1440)',
    'CHECK (endMin >= 0 AND endMin <= 1440)',
  ];
}

@DriftDatabase(tables: [Diaries, Schedules])
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  // ---------------- Diary CRUD ----------------

  /// 단일 일기 가져오기(없으면 null)
  Future<Diary?> getDiary(DateTime normalizedDate) {
    return (select(diaries)..where((t) => t.date.equals(normalizedDate)))
        .getSingleOrNull();
  }

  /// 단일 일기 스트림(화면 바인딩용)
  Stream<Diary?> watchDiary(DateTime normalizedDate) {
    return (select(diaries)..where((t) => t.date.equals(normalizedDate)))
        .watchSingleOrNull();
  }

  /// 일기 Upsert
  /// NOTE:
  ///   - `DiariesCompanion.insert`는 필드 타입이 (required T) 형태일 수 있어
  ///     nullable 컬럼(imagePath) 제어가 불편할 수 있음.
  ///   - 그래서 일반 `DiariesCompanion`을 사용하고 각 필드를 `Value(...)`로 지정.
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

  Future<void> deleteDiary(DateTime normalizedDate) async {
    await (delete(diaries)..where((t) => t.date.equals(normalizedDate))).go();
  }

  // ---------------- Schedule CRUD ----------------

  Future<List<Schedule>> listSchedules(DateTime normalizedDate) {
    return (select(schedules)
          ..where((t) => t.date.equals(normalizedDate))
          ..orderBy([(t) => OrderingTerm.asc(t.startMin)]))
        .get();
  }

  Stream<List<Schedule>> watchSchedulesInRange(DateTime start, DateTime end) {
    return (select(schedules)
          ..where((t) => t.date.isBetweenValues(start, end))
          ..orderBy([
            (t) => OrderingTerm.asc(t.date),
            (t) => OrderingTerm.asc(t.startMin)
          ]))
        .watch();
  }

  Future<int> insertSchedule(SchedulesCompanion comp) =>
      into(schedules).insert(comp);

  Future<bool> updateSchedule(SchedulesCompanion comp) =>
      update(schedules).replace(comp);

  Future<int> deleteSchedule(int id) =>
      (delete(schedules)..where((t) => t.id.equals(id))).go();
}

/// 앱 문서 폴더에 'app.sqlite'로 저장
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'app.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
