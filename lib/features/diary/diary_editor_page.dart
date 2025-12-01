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

  /// 이미지 또는 영상 경로 (로컬 파일 경로 OR Firebase Storage URL)
  String? _imagePath;

  final _picker = ImagePicker();

  bool _saving = false;

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
        _imagePath = d.imagePath; // 이미지 또는 영상 URL
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

  bool _isVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.webm') ||
        lower.contains('diary_videos'); // Storage 폴더 이름 기준으로도 체크
  }

  /// -------------------------------
  /// 사진 선택 (갤러리)
  /// -------------------------------
  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() {
      _imagePath = xfile.path; // 로컬 파일 경로
    });
  }

  /// -------------------------------
  /// 영상 선택 (갤러리)
  /// -------------------------------
  Future<void> _pickVideo() async {
    final xfile = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (xfile == null) return;

    setState(() {
      _imagePath = xfile.path; // 로컬 파일 경로
    });
  }

  /// 첨부 제거
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

    // Provider 대신 싱글톤 사용
    final storage = StorageService.instance;

    if (_isVideoPath(path)) {
      // 영상 업로드
      return await storage.uploadDiaryVideo(file);
    } else {
      // 이미지 업로드
      return await storage.uploadDiaryImage(file);
    }
  }

  Future<void> _save() async {
    final provider = context.read<DiaryProvider>();
    final date = provider.selectedDate;

    if (_saving) return;

    setState(() => _saving = true);

    try {
      final uploadedPath = await _ensureUploadedToStorage(_imagePath);

      await provider.save(
        emotion: _emotion,
        title: _title.text,
        content: _content.text,
        imagePath: uploadedPath,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '저장됨 (${date.year}.${date.month}.${date.day})',
          ),
        ),
      );

      setState(() {
        _imagePath = uploadedPath;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 중 오류가 발생했습니다: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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
                    },
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.red),
              ),
            ),

            /// 저장 버튼
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
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
                  onSelected: (v) {
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

                /// 이미지/영상 추가/제거 버튼
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('사진 추가'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _pickVideo,
                      icon: const Icon(Icons.videocam),
                      label: const Text('영상 추가'),
                    ),
                    const SizedBox(width: 8),
                    if (_imagePath != null)
                      TextButton.icon(
                        onPressed: _clearImage,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('첨부 제거'),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                /// 이미지/영상 미리보기
                _buildMediaPreview(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// -------------------------------
  /// 이미지/영상 미리보기
  /// -------------------------------
  Widget _buildMediaPreview(BuildContext context) {
    if (_imagePath == null) return const SizedBox.shrink();

    final path = _imagePath!;
    final radius = BorderRadius.circular(12);

    // 영상일 때
    if (_isVideoPath(path)) {
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: radius,
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.videocam, size: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                '영상이 선택되었습니다.\n저장 후 상세 화면에서 재생할 수 있습니다.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      );
    }

    // 이미지일 때
    final isUrl = path.startsWith('http');

    if (isUrl) {
      // URL 이미지
      return ClipRRect(
        borderRadius: radius,
        child: Image.network(
          path,
          height: 220,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _errorImg(context),
        ),
      );
    }

    // 로컬 이미지
    final file = File(path);
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
      child: const Text('이미지/영상을 불러올 수 없습니다.'),
    );
  }
}
