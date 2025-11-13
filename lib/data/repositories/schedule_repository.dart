/// ScheduleRepository
///  - startMin/endMin은 0~1440
///  - view단에서 DatePicker/TimePicker 값 → 분 단위로 환산해 저장
import 'package:drift/drift.dart';
import '../drift/drift_database.dart';

class ScheduleRepository {
  final LocalDatabase _db;
  ScheduleRepository(this._db);

  DateTime normalize(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  Future<List<Schedule>> listByDate(DateTime date) =>
      _db.listSchedules(normalize(date));

  Stream<List<Schedule>> watchRange(DateTime start, DateTime end) =>
      _db.watchSchedulesInRange(normalize(start), normalize(end));

  Future<int> insert({
    required DateTime date,
    required int startMin,
    required int endMin,
    required String title,
    String? memo,
  }) {
    final comp = SchedulesCompanion.insert(
      date: normalize(date),
      startMin: startMin,
      endMin: endMin,
      title: title,
      memo: memo == null ? const Value.absent() : Value(memo),
    );
    return _db.insertSchedule(comp);
  }

  Future<bool> update({
    required int id,
    required DateTime date,
    required int startMin,
    required int endMin,
    required String title,
    String? memo,
  }) {
    final comp = SchedulesCompanion(
      id: Value(id),
      date: Value(normalize(date)),
      startMin: Value(startMin),
      endMin: Value(endMin),
      title: Value(title),
      memo: memo == null ? const Value.absent() : Value(memo),
    );
    return _db.updateSchedule(comp);
  }

  Future<int> delete(int id) => _db.deleteSchedule(id);
}
