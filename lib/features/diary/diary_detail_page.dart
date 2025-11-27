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
    return DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(d.toLocal());
  }

  String _emotionLabel(int emotion) {
    switch (emotion) {
      case 1:
        return '😭 매우 안 좋음';
      case 2:
        return '☹️ 안 좋음';
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

  @override
  Widget build(BuildContext context) {
    final dateLabel = _formatDate(diary.date);

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

              /// 이미지 or 영상 있으면 표시
              if (diary.imagePath != null &&
                  diary.imagePath!.trim().isNotEmpty)
                _MediaPreview(path: diary.imagePath!),
            ],
          ),
        ),
      ),
    );
  }
}

class _MediaPreview extends StatefulWidget {
  final String path;

  const _MediaPreview({required this.path});

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
    final p = widget.path;
    _isNetwork = p.startsWith('http');

    // 단순 확장자 기반으로 영상 여부 판별
    final lower = p.toLowerCase();
    const videoExt = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];

    _isVideo = videoExt.any((ext) => lower.endsWith(ext));

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
    if (oldWidget.path != widget.path) {
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
    // 영상이 아닌 경우: 이미지 처리
    if (!_isVideo) {
      if (_isNetwork) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            widget.path,
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stack) => Container(
              height: 220,
              color: Theme.of(context).colorScheme.surfaceVariant,
              alignment: Alignment.center,
              child: const Text('이미지를 불러올 수 없습니다.'),
            ),
          ),
        );
      } else {
        final file = File(widget.path);
        if (!file.existsSync()) {
          return Container(
            height: 220,
            color: Theme.of(context).colorScheme.surfaceVariant,
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
              color: Theme.of(context).colorScheme.surfaceVariant,
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
