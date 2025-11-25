/// DiaryRepository
///  - 날짜 정규화(UTC 자정) 유틸 포함
///  - DB + Firestore 동시 관리
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import '../drift/drift_database.dart';

class DiaryRepository {
  final LocalDatabase _db;
  DiaryRepository(this._db);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// yyyy-mm-dd 기준으로 UTC 자정으로 고정
  DateTime normalize(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  /// Firestore 컬렉션
  CollectionReference<Map<String, dynamic>> get _diariesCol =>
      _firestore.collection('diaries');

  /// 날짜 → 문서 ID (예: 2025-11-25)
  String _docIdFromDate(DateTime date) {
    final d = normalize(date);
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '$y-$m-$dd';
  }

  /// Diary → Map (Firestore 저장용)
  Map<String, dynamic> _diaryToMap(Diary diary) {
    return {
      'date': diary.date.toUtc(),
      'emotion': diary.emotion,
      'title': diary.title,
      'content': diary.content,
      'imagePath': diary.imagePath,
      'createdAt': diary.createdAt.toUtc(),
      'updatedAt': diary.updatedAt.toUtc(),
    };
  }

  Future<Diary?> get(DateTime date) => _db.getDiary(normalize(date));

  Stream<Diary?> watch(DateTime date) => _db.watchDiary(normalize(date));

  /// 로컬 DB upsert + Firestore 동기화
  Future<void> upsert({
    required DateTime date,
    required int emotion,
    required String title,
    required String content,
    String? imagePath,
  }) async {
    final normalized = normalize(date);

    // 1) 로컬 DB 저장/업데이트
    await _db.upsertDiary(
      normalizedDate: normalized,
      emotion: emotion,
      title: title,
      content: content,
      imagePath: imagePath,
    );

    // 2) Firestore 동기화 (망가져도 앱은 안 죽게 try/catch)
    try {
      final diary = await _db.getDiary(normalized);
      if (diary != null) {
        await _diariesCol
            .doc(_docIdFromDate(normalized))
            .set(_diaryToMap(diary));
      }
    } catch (e) {
      // 네트워크 끊김 등은 일단 무시 (로컬은 이미 저장됨)
    }
  }

  /// 로컬 + Firestore 둘 다 삭제
  Future<void> delete(DateTime date) async {
    final normalized = normalize(date);

    // 1) 로컬 삭제
    await _db.deleteDiary(normalized);

    // 2) Firestore 삭제
    try {
      await _diariesCol.doc(_docIdFromDate(normalized)).delete();
    } catch (e) {
      // 여기서 실패해도 앱은 계속 동작
    }
  }
}
