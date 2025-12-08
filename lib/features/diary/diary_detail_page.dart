import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';

import 'package:diary_calendar_app/data/drift/drift_database.dart';

class DiaryDetailPage extends StatelessWidget {
  final Diary diary;

  const DiaryDetailPage({
    super.key,
    required this.diary,
  });

  String _formatDate(DateTime d) {
    // locale('ko_KR') 제거한 버전
    return DateFormat('yyyy.MM.dd (E)').format(d.toLocal());
  }

  String _emotionLabel(int emotion) {
    switch (emotion) {
      case 1:
        return '😭 매우 나쁨';
      case 2:
        return '☹️ 나쁨';
      case 3:
        return '😐 보통';
      case 4:
        return '😊 좋음';
      case 5:
        return '🤩 매우 좋음';
      default:
        return '😐 보통';
    }
  }

  /// 확장자/경로 기반으로 영상 여부 판단 (호환용)
  bool _isVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.m4v') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv') ||
        lower.endsWith('.webm') ||
        lower.contains('diary_videos');
  }

  /// imagePath(String?)를 여러 개의 미디어 리스트로 파싱
  /// - 새 버전: JSON 리스트 문자열
  /// - 옛 버전: 단일 경로 문자열
  List<_DiaryMedia> _decodeMedias(String? raw) {
    if (raw == null) return [];
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return [];

    // 새 버전(JSON 리스트)
    if (trimmed.startsWith('[')) {
      try {
        final List list = jsonDecode(trimmed) as List;
        return list.map((e) {
          final map = e as Map<String, dynamic>;
          final path = map['path'] as String;
          final isVideo = (map['isVideo'] as bool?) ?? _isVideoPath(path);
          return _DiaryMedia(path: path, isVideo: isVideo);
        }).toList();
      } catch (e) {
        debugPrint('Failed to decode medias json: $e');
        // 파싱 실패하면 그냥 무시
        return [];
      }
    }

    // 옛 버전: 단일 문자열 그대로 사용
    final isVideo = _isVideoPath(trimmed);
    return [
      _DiaryMedia(path: trimmed, isVideo: isVideo),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(diary.date);
    final medias = _decodeMedias(diary.imagePath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('다이어리 상세'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// 날짜 + 감정
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _emotionLabel(diary.emotion),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              /// 제목
              Text(
                diary.title.isEmpty ? '(제목 없음)' : diary.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),

              /// 본문
              Text(
                diary.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),

              /// 이미지/영상 여러 개 슬라이드
              if (medias.isNotEmpty) ...[
                Text(
                  '첨부된 사진/영상 (${medias.length})',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),

                SizedBox(
                  height: 260,
                  child: PageView.builder(
                    itemCount: medias.length,
                    itemBuilder: (context, index) {
                      final media = medias[index];
                      return Stack(
                        children: [
                          Center(
                            child: _MediaPreview(media: media),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '${index + 1} / ${medias.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 내부에서 사용할 다이어리 미디어 모델
class _DiaryMedia {
  final String path;
  final bool isVideo;

  const _DiaryMedia({
    required this.path,
    required this.isVideo,
  });
}

class _MediaPreview extends StatefulWidget {
  final _DiaryMedia media;

  const _MediaPreview({required this.media});

  @override
  State<_MediaPreview> createState() => _MediaPreviewState();
}

class _MediaPreviewState extends State<_MediaPreview> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isNetwork = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  void _initMedia() {
    final p = widget.media.path.trim();
    if (p.isEmpty) return;

    _isNetwork = p.startsWith('http');

    // JSON에서 isVideo를 넘겨받긴 하지만,
    // 혹시 몰라서 경로 확장자도 한 번 더 체크
    bool isVideoByExt() {
      final uri = Uri.parse(p);
      final pathLower = uri.path.toLowerCase();
      const videoExt = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
      return videoExt.any((ext) => pathLower.endsWith(ext)) ||
          pathLower.contains('diary_videos');
    }

    _isVideo = widget.media.isVideo || isVideoByExt();

    if (_isVideo) {
      if (_isNetwork) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(p));
      } else {
        _videoController = VideoPlayerController.file(File(p));
      }

      _videoController!.initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _initialized = true;
        });
      });
    }
  }

  @override
  void didUpdateWidget(covariant _MediaPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.media.path != widget.media.path ||
        oldWidget.media.isVideo != widget.media.isVideo) {
      _videoController?.dispose();
      _videoController = null;
      _initialized = false;
      _initMedia();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.media.path;

    // 🔹 영상이 아닌 경우: 이미지 처리
    if (!_isVideo) {
      if (_isNetwork) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            path,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              height: 220,
              color:
                  Theme.of(context).colorScheme.surfaceVariant,
              alignment: Alignment.center,
              child: const Text('이미지를 불러올 수 없습니다.'),
            ),
          ),
        );
      } else {
        final file = File(path);
        if (!file.existsSync()) {
          return Container(
            height: 220,
            width: double.infinity,
            color:
                Theme.of(context).colorScheme.surfaceVariant,
            alignment: Alignment.center,
            child: const Text('이미지 파일이 존재하지 않습니다.'),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            file,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              height: 220,
              color:
                  Theme.of(context).colorScheme.surfaceVariant,
              alignment: Alignment.center,
              child: const Text('이미지를 불러올 수 없습니다.'),
            ),
          ),
        );
      }
    }

    // 🔹 영상인 경우
    if (!_initialized || _videoController == null) {
      return Container(
        height: 220,
        width: double.infinity,
        color: Theme.of(context).colorScheme.surfaceVariant,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '첨부 영상',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoPlayer(_videoController!),
              IconButton(
                iconSize: 48,
                icon: Icon(
                  _videoController!.value.isPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  color: Colors.white,
                ),
                onPressed: () {
                  setState(() {
                    if (_videoController!.value.isPlaying) {
                      _videoController!.pause();
                    } else {
                      _videoController!.play();
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
