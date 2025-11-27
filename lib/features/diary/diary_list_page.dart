import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart' as drift;

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
    // ✅ Drift 기본 쿼리로 diaries 전체 가져오기
    final query = _db.select(_db.diaries)
      ..orderBy([
        (tbl) => drift.OrderingTerm(
              expression: tbl.date,
              mode: drift.OrderingMode.desc,
            ),
      ]);

    final list = await query.get();

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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
