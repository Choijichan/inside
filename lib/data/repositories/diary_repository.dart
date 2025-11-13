/// DiaryRepository
///  - 날짜 정규화(UTC 자정) 유틸 포함
///  - DB 접근을 화면/비즈니스 로직과 분리
import 'package:drift/drift.dart';
import '../drift/drift_database.dart';

class DiaryRepository {
  final LocalDatabase _db;
  DiaryRepository(this._db);

  /// yyyy-mm-dd 기준으로 UTC 자정으로 고정
  DateTime normalize(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  Future<Diary?> get(DateTime date) => _db.getDiary(normalize(date));
  Stream<Diary?> watch(DateTime date) => _db.watchDiary(normalize(date));

  Future<void> upsert({
    required DateTime date,
    required int emotion,
    required String title,
    required String content,
    String? imagePath,
  }) =>
      _db.upsertDiary(
        normalizedDate: normalize(date),
        emotion: emotion,
        title: title,
        content: content,
        imagePath: imagePath,
      );

  Future<void> delete(DateTime date) => _db.deleteDiary(normalize(date));
}
