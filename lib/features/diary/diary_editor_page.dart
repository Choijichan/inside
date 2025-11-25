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
  int _emotion = 2;

  /// 💡 이 값은 "로컬 경로"일 수도 있고 "Storage URL"일 수도 있다.
  String? _imagePath;

  void _loadFromProvider() {
    final provider = context.read<DiaryProvider>();
    final d = provider.current;
    _title.text = d?.title ?? '';
    _content.text = d?.content ?? '';
    _emotion = d?.emotion ?? 2;
    _imagePath = d?.imagePath;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFromProvider();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadFromProvider();
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
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }

  /// ✅ 저장 전에: 로컬 파일이면 Firebase Storage에 업로드해서 URL로 바꿔주는 함수
  Future<String?> _ensureUploadedToStorage(String? path) async {
    if (path == null) return null;

    // 이미 URL이면(=이전에 업로드된 상태면) 그대로 사용
    if (path.startsWith('http')) {
      return path;
    }

    final file = File(path);
    if (!await file.exists()) {
      return path; // 파일이 없으면 그냥 원래 값 반환
    }

    final isVideo = _isVideoPath(path);
    String url;

    if (isVideo) {
      url = await StorageService.instance.uploadDiaryVideo(file);
    } else {
      url = await StorageService.instance.uploadDiaryImage(file);
    }

    return url;
  }

  /// 📷 이미지 선택 (로컬 경로만 세팅, Storage 업로드는 "저장 버튼"에서 처리)
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2048,
    );
    if (picked == null) return;

    setState(() {
      _imagePath = picked.path; // 로컬 경로
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('이미지 선택됨 (저장 시 업로드)')),
    );
  }

  /// 🎬 영상 선택 (로컬 경로 세팅, 저장 시 Storage에 업로드)
  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(
      source: ImageSource.gallery,
    );
    if (picked == null) return;

    setState(() {
      _imagePath = picked.path; // 로컬 경로
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('영상 선택됨 (저장 시 업로드)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final d = provider.current;

    return Scaffold(
      resizeToAvoidBottomInset: false, // 한글 입력 버그 방지
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

                    /// ⭐ 삭제 후 이전 화면으로 이동
                    Navigator.of(context).pop();
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

              /// ⭐ 저장 후 이전 화면으로 이동
              Navigator.of(context).pop();
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

              /// 감정 선택 위젯
              EmotionPicker(
                value: _emotion,
                onPicked: (v) => setState(() => _emotion = v),
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
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                minLines: 8,
                maxLines: 20,
                decoration: const InputDecoration(
                  labelText: '내용',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 20),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('사진 첨부'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: _pickVideo,
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('영상 첨부'),
                  ),
                ],
              ),

              const SizedBox(height: 8),
              if (_imagePath != null)
                Text(
                  _imagePath!,
                  overflow: TextOverflow.ellipsis,
                ),

              const SizedBox(height: 16),

              /// 미리보기 (이미지/영상 구분 + 로컬/URL 구분)
              if (_imagePath != null) ...[
                _buildMediaPreview(context, _imagePath!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPreview(BuildContext context, String path) {
    final isNetwork = path.startsWith('http');
    final isVideo = _isVideoPath(path);

    if (isVideo) {
      // 에디터 화면에서는 간단하게 "영상 선택됨" 정도만 보여주고,
      // 실제 재생은 DiaryDetailPage에서 하도록 두는 구조.
      return Container(
        height: 120,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam),
            SizedBox(width: 8),
            Text('영상이 첨부되었습니다. (상세 화면에서 재생)'),
          ],
        ),
      );
    }

    // 이미지인 경우: 로컬 / 네트워크 둘 다 처리
    if (isNetwork) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          path,
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
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(path),
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
