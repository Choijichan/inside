import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:diary_calendar_app/data/drift/drift_database.dart';

class DiaryDetailPage extends StatelessWidget {
  final Diary diary;

  const DiaryDetailPage({
    super.key,
    required this.diary,
  });

  @override
  Widget build(BuildContext context) {
    final dateLabel =
        DateFormat('yyyy.MM.dd (E)', 'ko_KR').format(diary.date.toLocal());

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
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '감정: ${diary.emotion}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  // 필요하면 감정 이모지/텍스트 매핑 넣어도 됨
                ],
              ),
              const SizedBox(height: 16),
              Text(
                diary.title.isEmpty ? '(제목 없음)' : diary.title,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text(
                diary.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              if (diary.imagePath != null && diary.imagePath!.isNotEmpty)
                _buildImage(context, diary.imagePath!),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(BuildContext context, String path) {
    final isUrl = path.startsWith('http');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '첨부 사진',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: isUrl
              ? Image.network(
                  path,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  path,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
        ),
      ],
    );
  }
}
