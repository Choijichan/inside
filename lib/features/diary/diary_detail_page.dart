import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../data/drift/drift_database.dart';

class DiaryDetailPage extends StatelessWidget {
  final Diary diary;

  const DiaryDetailPage({
    super.key,
    required this.diary,
  });

  String _formatDate(DateTime d) {
    // yyyy-MM-dd 형태로 보여주기
    return d.toIso8601String().substring(0, 10);
  }

  @override
  Widget build(BuildContext context) {
    final mediaPath = diary.imagePath; // 이미지/영상 공용 경로로 사용

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(diary.date)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 감정/제목/날짜
            Row(
              children: [
                Icon(
                  Icons.emoji_emotions,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '감정: ${diary.emotion}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Text(
                  _formatDate(diary.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              diary.title.isEmpty ? '(제목 없음)' : diary.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              diary.content,
              style: Theme.of(context).textTheme.bodyLarge,
            ),

            // 미디어(이미지 or 영상)
            if (mediaPath != null) ...[
              const SizedBox(height: 24),
              const Text(
                '첨부 미디어',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DiaryMediaView(path: mediaPath),
            ],
          ],
        ),
      ),
    );
  }
}

/// 이미지/영상 공통 처리 위젯
class DiaryMediaView extends StatefulWidget {
  final String path;

  const DiaryMediaView({super.key, required this.path});

  @override
  State<DiaryMediaView> createState() => _DiaryMediaViewState();
}

class _DiaryMediaViewState extends State<DiaryMediaView> {
  VideoPlayerController? _videoController;
  bool _isVideo = false;
  bool _isNetwork = false;
  bool _initialized = false;

  bool _isVideoPath(String path) {
    final lower = path.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }

  @override
  void initState() {
    super.initState();
    _isVideo = _isVideoPath(widget.path);
    _isNetwork = widget.path.startsWith('http');

    if (_isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    if (_isNetwork) {
      _videoController =
          VideoPlayerController.networkUrl(Uri.parse(widget.path));
    } else {
      _videoController = VideoPlayerController.file(File(widget.path));
    }

    await _videoController!.initialize();
    _videoController!.setLooping(true);

    if (!mounted) return;
    setState(() {
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 🔹 영상이 아닌 경우: 이미지로 처리
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
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(widget.path),
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
    if (!_initialized) {
      return Container(
        height: 220,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return Column(
      children: [
        AspectRatio(
          aspectRatio: _videoController!.value.aspectRatio,
          child: VideoPlayer(_videoController!),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _videoController!.value.isPlaying ? Icons.pause : Icons.play_arrow,
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
      ],
    );
  }
}
