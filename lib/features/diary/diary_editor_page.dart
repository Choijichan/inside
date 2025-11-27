import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:diary_calendar_app/core/storage_service.dart';
import 'package:diary_calendar_app/features/common/widgets/emotion_picker.dart';
import 'package:diary_calendar_app/features/diary/diary_provider.dart';

class DiaryEditorPage extends StatefulWidget {
  const DiaryEditorPage({super.key});

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  int _emotion = 3; // 기본값
  String? _imagePath; // 로컬 파일 경로 OR Firebase Storage URL

  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();

    // 화면 build 이후 provider 값 반영
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<DiaryProvider>();
      final d = provider.current;

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

  /// -------------------------------
  /// 이미지 선택 (갤러리)
  /// -------------------------------
  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() {
      _imagePath = xfile.path; // 로컬 파일 경로
    });
  }

  /// 이미지 제거
  void _clearImage() {
    setState(() {
      _imagePath = null;
    });
  }

  /// 로컬 파일이면 Storage 업로드 → URL 반환
  Future<String?> _ensureUploadedToStorage(String? path) async {
    if (path == null) return null;
    if (path.startsWith('http')) return path; // 이미 URL이면 그대로

    final file = File(path);
    if (!file.existsSync()) return null;

    final storage = context.read<StorageService>();
    final url = await storage.uploadDiaryImage(file);

    return url;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final d = provider.current;

    final date = provider.selectedDate;
    final dateLabel = "${date.year}.${date.month}.${date.day}";

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("다이어리 — $dateLabel"),
          actions: [
            /// 삭제 버튼
            TextButton(
              onPressed: d == null
                  ? null
                  : () async {
                      await provider.delete();

                      if (!mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('삭제 완료')),
                      );

                      /// pop 제거 (탭 루트 화면이기 때문에)
                    },
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.red),
              ),
            ),

            /// 저장 버튼
            TextButton(
              onPressed: () async {
                final uploadedPath =
                    await _ensureUploadedToStorage(_imagePath);

                await provider.save(
                  emotion: _emotion,
                  title: _title.text,
                  content: _content.text,
                  imagePath: uploadedPath,
                );

                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('저장됨')),
                );

                setState(() {
                  _imagePath = uploadedPath;
                });

                /// pop 없음
              },
              child: const Text(
                '저장',
                style: TextStyle(color: Colors.blue),
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
                /// 감정 선택
                Text(
                  '오늘 기분은 어떤가요?',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                EmotionPicker(
                  value: _emotion,
                  onSelected: (v) {          // 🔴 여기 수정 (onChanged → onSelected)
                    setState(() {
                      _emotion = v;
                    });
                  },
                ),

                const SizedBox(height: 20),

                /// 제목
                TextField(
                  controller: _title,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),

                /// 내용
                TextField(
                  controller: _content,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  minLines: 5,
                  maxLines: null,
                ),
                const SizedBox(height: 16),

                /// 이미지 추가/제거 버튼
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('사진 추가'),
                    ),
                    const SizedBox(width: 10),
                    if (_imagePath != null)
                      TextButton.icon(
                        onPressed: _clearImage,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('사진 제거'),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                /// 이미지 미리보기
                _buildImagePreview(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// -------------------------------
  /// 이미지 미리보기
  /// -------------------------------
  Widget _buildImagePreview(BuildContext context) {
    if (_imagePath == null) return const SizedBox.shrink();

    final isUrl = _imagePath!.startsWith('http');
    final radius = BorderRadius.circular(12);

    if (isUrl) {
      // URL 이미지
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          _imagePath!,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _errorImg(context),
        ),
      );
    }

    // 로컬 이미지
    final file = File(_imagePath!);
    if (!file.existsSync()) return _errorImg(context);

    return ClipRRect(
      borderRadius: radius,
      child: Image.file(
        file,
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorImg(context),
      ),
    );
  }

  Widget _errorImg(BuildContext context) {
    return Container(
      height: 220,
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant,
      alignment: Alignment.center,
      child: const Text('이미지를 불러올 수 없습니다.'),
    );
  }
}
