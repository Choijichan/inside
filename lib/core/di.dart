import 'package:get_it/get_it.dart';
import '../data/drift/drift_database.dart';
import '../data/repositories/diary_repository.dart';
import '../data/repositories/schedule_repository.dart';

// GetIt DI 컨테이너
final GetIt getIt = GetIt.instance;

// 앱 시작 시 한 번만 호출
Future<void> setupDI() async {
  // 1) DB 인스턴스
  final db = LocalDatabase();
  getIt.registerSingleton<LocalDatabase>(db);

  // 2) Repository
  getIt.registerLazySingleton<DiaryRepository>(() => DiaryRepository(getIt()));
  getIt.registerLazySingleton<ScheduleRepository>(() => ScheduleRepository(getIt()));
}
