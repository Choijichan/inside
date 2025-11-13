import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../common/widgets/emotion_picker.dart';
import 'diary_provider.dart';

class DiaryEditorPage extends StatefulWidget {
  const DiaryEditorPage({super.key});

  @override
  State<DiaryEditorPage> createState() => _DiaryEditorPageState();
}

class _DiaryEditorPageState extends State<DiaryEditorPage> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  int _emotion = 2;
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DiaryProvider>();
    final d = provider.current;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          '다이어리 — ${provider.selectedDate.year}-${provider.selectedDate.month}-${provider.selectedDate.day}',
        ),
        actions: [
          /// ⭐ 삭제 버튼 (텍스트버튼)
          TextButton(
            onPressed: d == null
                ? null
                : () async {
                    await provider.delete();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('삭제 완료')),
                      );
                    }
                  },
            child: const Text(
              '삭제',
              style: TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),

          /// ⭐ 저장 버튼 (텍스트버튼)
          TextButton(
            onPressed: () async {
              await provider.save(
                emotion: _emotion,
                title: _title.text,
                content: _content.text,
                imagePath: _imagePath,
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('저장됨')),
                );
              }
            },
            child: const Text(
              '저장',
              style: TextStyle(color: Colors.blue, fontSize: 16),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              '오늘 기분은 어떤가요?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            EmotionPicker(
              value: _emotion,
              onPicked: (v) => setState(() => _emotion = v),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: '제목'),
            ),

            const SizedBox(height: 12),
            TextField(
              controller: _content,
              minLines: 6,
              maxLines: 12,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(labelText: '내용'),
            ),

            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final p = await provider.pickAndSaveImage();
                    if (p != null) {
                      setState(() => _imagePath = p);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('이미지 첨부됨')),
                      );
                    }
                  },
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('사진 첨부'),
                ),
                const SizedBox(width: 12),
                if (_imagePath != null)
                  Expanded(
                    child: Text(
                      _imagePath!,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),
            if (_imagePath != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(_imagePath!),
                  height: 180,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    height: 180,
                    alignment: Alignment.center,
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    child: const Text('이미지를 불러올 수 없습니다.'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
