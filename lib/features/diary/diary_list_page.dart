import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';

import 'package:diary_calendar_app/data/drift/drift_database.dart';
import 'package:diary_calendar_app/features/diary/diary_detail_page.dart';

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  final _db = GetIt.I<LocalDatabase>();

  bool _loading = true;
  List<Diary> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // TODO: 네 실제 LocalDatabase에 맞게 메서드 이름 조정하기
    // 예: getAllDiaries(), getDiariesBetween 등
    final from = DateTime.utc(2000, 1, 1);
    final to = DateTime.utc(2100, 1, 1);

    // 아래는 예시: getDiariesBetween(from, to) 가 있다고 가정
    final list = await _db.getDiariesBetween(from, to);

    list.sort((a, b) => b.date.compareTo(a.date));

    if (!mounted) return;
    setState(() {
      _rows = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('다이어리 목록'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _rows.isEmpty
                ? const Center(child: Text('작성한 다이어리가 없습니다.'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    itemBuilder: (context, index) {
                      final d = _rows[index];
                      final dateLabel =
                          DateFormat('yyyy.MM.dd').format(d.date.toLocal());
                      return ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        title: Text(
                          d.title.isEmpty ? '(제목 없음)' : d.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dateLabel,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              d.content,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DiaryDetailPage(diary: d),
                            ),
                          );
                        },
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const Divider(height: 1, thickness: 0.5),
                    itemCount: _rows.length,
                  ),
      ),
    );
  }
}
