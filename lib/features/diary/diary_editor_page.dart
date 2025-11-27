import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';

import '../common/widgets/emotion_picker.dart';
import 'diary_provider.dart';
import '../../core/storage_service.dart';

class DiaryEditorPage extends StatefulWidget {
  const DiaryEditorPage({super.key});

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  int _emotion = 3; // 기본값
  String? _imagePath; // 로컬 경로 또는 Firebase URL

  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DiaryProvider>();
      final d = provider.currentDiary;

      if (d != null) {
        _emotion = d.emotion;
        _title.text = d.title;
        _content.text = d.content;
        _imagePath = d.imagePath;
      } else {
        _emotion = 3;
        _title.clear();
        _content.clear();
        _imagePath = null;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  /// 이미지 선택 (갤러리)
  Future<void> _pickImage() async {
    final xfile = await _imagePicker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() {
      _imagePath = xfile.path; // 로컬 경로
    });
  }

  /// 이미지 제거
  void _clearImage() {
    setState(() {
      _imagePath = null;
    });
  }

  /// 현재 _imagePath가 "로컬 경로"라면 Storage에 업로드해서 URL로 바꾸고,
  /// 이미 URL이면 그대로 반환
  Future<String?> _ensureUploadedToStorage(String? currentPath) async {
    if (currentPath == null) return null;
    // 간단하게 "http"로 시작하면 이미 URL이라고 가정
    if (currentPath.startsWith('http')) {
      return currentPath;
    }

    // 로컬 파일 → Firebase Storage 업로드
    final file = File(currentPath);
    if (!file.existsSync()) {
      return null;
    }

    final storageService = context.read<StorageService>();
    final downloadUrl = await storageService.uploadDiaryImage(file);
    return downloadUrl; // URL
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final d = provider.currentDiary;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // 키보드 내려주기
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '다이어리 — ${provider.selectedDate.year}-${provider.selectedDate.month}-${provider.selectedDate.day}',
          ),
          actions: [
            /// 🔥 삭제 버튼
            TextButton(
              onPressed: d == null
                  ? null
                  : () async {
                      await provider.delete();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('삭제 완료')),
                      );

                      /// ⭐ 삭제 후 이전 화면 이동 제거 (탭 구조 루트이므로 pop X)
                      // Navigator.of(context).pop();
                    },
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),

            /// 🔥 저장 버튼
            TextButton(
              onPressed: () async {
                // 1️⃣ 현재 _imagePath가 로컬 경로라면 → Storage에 업로드해서 URL로 변환
                final uploadedPath = await _ensureUploadedToStorage(_imagePath);

                // 2️⃣ provider.save 에는 "URL(or null)"을 넘김
                await provider.save(
                  emotion: _emotion,
                  title: _title.text,
                  content: _content.text,
                  imagePath: uploadedPath,
                );

                // 3️⃣ 상태에도 반영 (다음에 들어왔을 때도 URL 기준)
                setState(() {
                  _imagePath = uploadedPath;
                });

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('저장됨')),
                );

                /// ⭐ 저장 후 이전 화면 이동 제거 (탭 구조 루트이므로 pop X)
                // Navigator.of(context).pop();
              },
              child: const Text(
                '저장',
                style: TextStyle(color: Colors.blue, fontSize: 16),
              ),
            ),
          ],
        ),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '오늘 기분은 어떤가요?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                EmotionPicker(
                  value: _emotion,
                  onChanged: (v) {
                    setState(() {
                      _emotion = v;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _content,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  minLines: 5,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('사진 추가'),
                    ),
                    const SizedBox(width: 8),
                    if (_imagePath != null)
                      TextButton.icon(
                        onPressed: _clearImage,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('사진 제거'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildImagePreview(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    if (_imagePath == null) {
      return const SizedBox.shrink();
    }

    // URL인지 로컬파일인지 분기
    final isUrl = _imagePath!.startsWith('http');

    if (isUrl) {
      // 네트워크 이미지
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _imagePath!,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            height: 200,
            color: Theme.of(context).colorScheme.surfaceVariant,
            alignment: Alignment.center,
            child: const Text('이미지를 불러올 수 없습니다.'),
          ),
        ),
      );
    } else {
      // 로컬 파일 이미지
      final file = File(_imagePath!);
      if (!file.existsSync()) {
        return Container(
          height: 200,
          color: Theme.of(context).colorScheme.surfaceVariant,
          alignment: Alignment.center,
          child: const Text('이미지 파일이 존재하지 않습니다.'),
        );
      }

      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          file,
          height: 200,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stack) => Container(
            height: 200,
            color: Theme.of(context).colorScheme.surfaceVariant,
            alignment: Alignment.center,
            child: const Text('이미지를 불러올 수 없습니다.'),
          ),
        ),
      );
    }
  }
}
