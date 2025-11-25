/// ScheduleRepository
///  - startMin/endMin은 0~1440
///  - view단에서 DatePicker/TimePicker 값 → 분 단위로 환산해 저장
///  - 로컬 DB + Firestore 같이 관리
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart';
import '../drift/drift_database.dart';

class ScheduleRepository {
  final LocalDatabase _db;
  ScheduleRepository(this._db);

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  DateTime normalize(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  CollectionReference<Map<String, dynamic>> get _schedulesCol =>
      _firestore.collection('schedules');

  String _docIdFromId(int id) => id.toString();

  Map<String, dynamic> _scheduleToMap({
    required int id,
    required DateTime date,
    required int startMin,
    required int endMin,
    required String title,
    String? memo,
  }) {
    return {
      'id': id,
      'date': normalize(date).toUtc(),
      'startMin': startMin,
      'endMin': endMin,
      'title': title,
      'memo': memo,
    };
  }

  Future<List<Schedule>> listByDate(DateTime date) =>
      _db.listSchedules(normalize(date));

  Stream<List<Schedule>> watchRange(DateTime start, DateTime end) =>
      _db.watchSchedulesInRange(normalize(start), normalize(end));

  /// 일정 생성 + Firestore 저장
  Future<int> insert({
    required DateTime date,
    required int startMin,
    required int endMin,
    required String title,
    String? memo,
  }) async {
    final normalized = normalize(date);

    final comp = SchedulesCompanion.insert(
      date: normalized,
      startMin: startMin,
      endMin: endMin,
      title: title,
      memo: memo == null ? const Value.absent() : Value(memo),
    );

    // 1) 로컬 DB insert
    final id = await _db.insertSchedule(comp);

    // 2) Firestore에 반영
    try {
      await _schedulesCol.doc(_docIdFromId(id)).set(
            _scheduleToMap(
              id: id,
              date: normalized,
              startMin: startMin,
              endMin: endMin,
              title: title,
              memo: memo,
            ),
          );
    } catch (e) {}

    return id;
  }

  /// 일정 수정 + Firestore 업데이트
  Future<bool> update({
    required int id,
    required DateTime date,
    required int startMin,
    required int endMin,
    required String title,
    String? memo,
  }) async {
    final normalized = normalize(date);

    final comp = SchedulesCompanion(
      id: Value(id),
      date: Value(normalized),
      startMin: Value(startMin),
      endMin: Value(endMin),
      title: Value(title),
      memo: memo == null ? const Value.absent() : Value(memo),
    );

    // 1) 로컬 DB 업데이트
    final ok = await _db.updateSchedule(comp);

    // 2) Firestore 업데이트
    if (ok) {
      try {
        await _schedulesCol.doc(_docIdFromId(id)).set(
              _scheduleToMap(
                id: id,
                date: normalized,
                startMin: startMin,
                endMin: endMin,
                title: title,
                memo: memo,
              ),
              SetOptions(merge: true),
            );
      } catch (e) {}
    }

    return ok;
  }

  /// 일정 삭제 + Firestore 삭제
  Future<int> delete(int id) async {
    // 1) 로컬에서 삭제
    final rows = await _db.deleteSchedule(id);

    // 2) Firestore에서도 삭제
    try {
      await _schedulesCol.doc(_docIdFromId(id)).delete();
    } catch (e) {}

    return rows;
  }
}
