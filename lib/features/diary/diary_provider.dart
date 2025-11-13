import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/drift/drift_database.dart';
import '../../data/repositories/diary_repository.dart';

/// Step 3: 다이어리 CRUD + 이미지 첨부 지원
class DiaryProvider extends ChangeNotifier {
  final DiaryRepository _repo = GetIt.I<DiaryRepository>();

  DateTime selectedDate = _normalize(DateTime.now());
  Diary? current;

  StreamSubscription<Diary?>? _sub;

  static DateTime _normalize(DateTime d) => DateTime.utc(d.year, d.month, d.day);

  DiaryProvider() {
    _listenDate(selectedDate);
  }

  void _listenDate(DateTime d) {
    _sub?.cancel();
    _sub = _repo.watch(d).listen((value) {
      current = value;
      notifyListeners();
    });
  }

  void setDate(DateTime d) {
    selectedDate = _normalize(d);
    _listenDate(selectedDate);
  }

  Future<void> save({
    required int emotion,
    required String title,
    required String content,
    String? imagePath,
  }) async {
    await _repo.upsert(
      date: selectedDate,
      emotion: emotion,
      title: title,
      content: content,
      imagePath: imagePath,
    );
  }

  Future<void> delete() async {
    await _repo.delete(selectedDate);
  }

  /// 갤러리에서 이미지 선택 → 앱 문서 폴더에 복사 → 경로 반환
  Future<String?> pickAndSaveImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 2048);
    if (picked == null) return null;
    final dir = await getApplicationDocumentsDirectory();
    final fileName = 'diary_${selectedDate.toIso8601String().substring(0,10)}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final saved = File('${dir.path}/$fileName');
    await File(picked.path).copy(saved.path);
    return saved.path;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
