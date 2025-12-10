import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:diary_calendar_app/core/storage_service.dart';
import 'package:diary_calendar_app/features/common/widgets/emotion_picker.dart';
import 'package:diary_calendar_app/features/diary/diary_provider.dart';

// 다이어리 첨부 미디어 (이미지 or 영상)
class DiaryMedia {
  final String path; // 로컬 파일 경로 또는 URL
  final bool isVideo;

  DiaryMedia({
    required this.path,
    required this.isVideo,
  });

  Map<String, dynamic> toJson() => {
        'path': path,
        'isVideo': isVideo,
      };

  factory DiaryMedia.fromJson(Map<String, dynamic> json) {
    return DiaryMedia(
      path: json['path'] as String,
      isVideo: (json['isVideo'] as bool?) ?? false,
    );
  }
}

class DiaryEditorPage extends StatefulWidget {
  const DiaryEditorPage({super.key});

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  static const int _maxMedias = 60; // 사진 + 영상 총합 최대 개수

  final _title = TextEditingController();
  final _content = TextEditingController();
  int _emotion = 3; // 기본값

  // 첨부된 이미지/영상 목록
  List<DiaryMedia> _medias = [];

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
        _medias = _decodeMediasFromRaw(d.imagePath);
      } else {
        _emotion = 3;
        _title.clear();
        _content.clear();
        _medias = [];
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
        lower.endsWith('.mkv') ||
        lower.contains('diary_videos'); // Storage 폴더 이름 기준으로도 체크
  }

  // DB의 imagePath(String?)를 List<DiaryMedia>로 변환
  List<DiaryMedia> _decodeMediasFromRaw(String? raw) {
    if (raw == null) return [];
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];

    if (trimmed.startsWith('[')) {
      try {
        final List list = jsonDecode(trimmed) as List;
        return list
            .map((e) =>
                DiaryMedia.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (e) {
        debugPrint('Failed to decode medias json: $e');
        return [];
      }
    }

    final isVideo = _isVideoPath(trimmed);
    return [
      DiaryMedia(path: trimmed, isVideo: isVideo),
    ];
  }

  // List<DiaryMedia> → JSON 문자열
  String? _encodeMediasToJson(List<DiaryMedia> medias) {
    if (medias.isEmpty) return null;
    final list = medias.map((m) => m.toJson()).toList();
    return jsonEncode(list);
  }

  // 사진 여러 장 선택 (갤러리)
  Future<void> _pickImages() async {
    if (_medias.length >= _maxMedias) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 $_maxMedias개까지 첨부할 수 있습니다.')),
      );
      return;
    }

    // image_picker는 사진은 여러장 선택 지원 (pickMultiImage)
    final xfiles = await _picker.pickMultiImage();
    if (xfiles == null || xfiles.isEmpty) return;

    final remain = _maxMedias - _medias.length;
    final selected = xfiles.take(remain);

    setState(() {
      for (final x in selected) {
        _medias.add(
          DiaryMedia(
            path: x.path, // 로컬 파일 경로
            isVideo: false,
          ),
        );
      }
    });
  }

  // 영상 선택 (갤러리)
  Future<void> _pickVideo() async {
    if (_medias.length >= _maxMedias) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('최대 $_maxMedias개까지 첨부할 수 있습니다.')),
      );
      return;
    }

    final xfile = await _picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(minutes: 5),
    );
    if (xfile == null) return;

    setState(() {
      _medias.add(
        DiaryMedia(
          path: xfile.path, // 로컬 파일 경로
          isVideo: true,
        ),
      );
    });
  }

  // 특정 인덱스 첨부 제거
  void _removeMediaAt(int index) {
    setState(() {
      _medias.removeAt(index);
    });
  }

  // 전체 첨부 제거
  void _clearAllMedias() {
    setState(() {
      _medias.clear();
    });
  }

  Future<List<DiaryMedia>> _uploadAllMedias(
      List<DiaryMedia> medias) async {
    final storage = StorageService.instance;

    final List<DiaryMedia> result = [];

    for (final media in medias) {
      final path = media.path;

      // 이미 URL이면 그대로 사용
      if (path.startsWith('http')) {
        result.add(media);
        continue;
      }

      final file = File(path);
      if (!file.existsSync()) {
        // 파일이 실제로 없으면 건너뜀
        debugPrint('File not found, skip: $path');
        continue;
      }

      try {
        String uploadedPath;
        if (media.isVideo) {
          uploadedPath = await storage.uploadDiaryVideo(file);
        } else {
          uploadedPath = await storage.uploadDiaryImage(file);
        }

        result.add(
          DiaryMedia(
            path: uploadedPath,
            isVideo: media.isVideo,
          ),
        );
      } catch (e) {
        // 업로드 실패 시 로컬 경로 유지
        debugPrint('Storage upload failed, keep local path: $e');
        result.add(media);
      }
    }

    return result;
  }

  Future<void> _save() async {
    final provider = context.read<DiaryProvider>();
    final date = provider.selectedDate;

    if (_saving) return;

    setState(() => _saving = true);

    try {
      // 모든 미디어 업로드 시도
      final uploadedMedias = await _uploadAllMedias(_medias);
      final mediaJson = _encodeMediasToJson(uploadedMedias);

      await provider.save(
        emotion: _emotion,
        title: _title.text,
        content: _content.text,
        imagePath: mediaJson, // JSON 문자열로 저장
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
        _medias = uploadedMedias;
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
                      onPressed: _pickImages,
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
                    if (_medias.isNotEmpty)
                      TextButton.icon(
                        onPressed: _clearAllMedias,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('전체 제거'),
                      ),
                  ],
                ),

                const SizedBox(height: 20),

                /// 이미지/영상 미리보기 (순번 표시)
                _buildMediaPreview(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// -------------------------------
  /// 이미지/영상 미리보기 (여러 개 + 순번)
  /// -------------------------------
  Widget _buildMediaPreview(BuildContext context) {
    if (_medias.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '첨부된 사진/영상 (${_medias.length}/$_maxMedias)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),

        // 가로로 스크롤되는 썸네일 리스트
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _medias.length,
            itemBuilder: (context, index) {
              final media = _medias[index];
              final path = media.path;

              Widget thumb;
              final radius = BorderRadius.circular(12);

              if (media.isVideo) {
                // 영상은 아이콘 + 텍스트 형태로 썸네일
                thumb = Container(
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceVariant,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.videocam),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '영상 ${index + 1}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              } else {
                // 이미지 썸네일
                final isUrl = path.startsWith('http');
                if (isUrl) {
                  thumb = ClipRRect(
                    borderRadius: radius,
                    child: Image.network(
                      path,
                      width: 140,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _errorImg(context),
                    ),
                  );
                } else {
                  final file = File(path);
                  if (!file.existsSync()) {
                    thumb = _errorImg(context);
                  } else {
                    thumb = ClipRRect(
                      borderRadius: radius,
                      child: Image.file(
                        file,
                        width: 140,
                        height: 120,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _errorImg(context),
                      ),
                    );
                  }
                }
              }

              // 순서 번호 배지 (1,2,3…)
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Stack(
                  children: [
                    thumb,
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: InkWell(
                        onTap: () => _removeMediaAt(index),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(4),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _errorImg(BuildContext context) {
    return Container(
      width: 140,
      height: 120,
      color: Theme.of(context).colorScheme.surfaceVariant,
      alignment: Alignment.center,
      child: const Text('불러올 수 없음'),
    );
  }
}
