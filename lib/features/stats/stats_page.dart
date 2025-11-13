import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../data/drift/drift_database.dart';

/// 간단 통계
/// - 이번 달 감정 분포 (바 형태)
/// - 연속 기록일(최대/현재)
class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  final db = GetIt.I<LocalDatabase>();
  late DateTime _first;
  late DateTime _last;
  List<Diary> _rows = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _first = DateTime.utc(now.year, now.month, 1);
    _last = DateTime.utc(now.year, now.month + 1, 0);
    _load();
  }

  Future<void> _load() async {
    final rows = await (db.select(db.diaries)
      ..where((t) => t.date.isBetweenValues(_first, _last)))
      .get();
    setState(() => _rows = rows);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('yyyy.MM');
    final Map<int, int> counts = {0:0,1:0,2:0,3:0,4:0};
    for (final r in _rows) {
      counts[r.emotion] = (counts[r.emotion] ?? 0) + 1;
    }
    final total = _rows.length;

    // Streak 계산(전체 기간 기준 간단 로직)
    // 모든 일기 날짜를 집합으로 모아 연속일 계산
    // NOTE: 실서비스에서는 전체 기간을 대상으로 수행하거나 캐시 필요
    // 여기서는 데모로 이번 달 범위 내에서만 계산
    final days = _rows.map((e) => e.date).toSet();
    int currentStreak = 0;
    int maxStreak = 0;
    final today = DateTime.utc(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    // 현재 연속일: 오늘부터 과거로 내려가며 체크
    var d = today;
    while (days.contains(d)) {
      currentStreak += 1;
      d = d.subtract(const Duration(days: 1));
    }
    // 최대 연속일(이번 달 내)
    d = _first;
    int run = 0;
    while (!d.isAfter(_last)) {
      if (days.contains(d)) {
        run += 1;
        if (run > maxStreak) maxStreak = run;
      } else {
        run = 0;
      }
      d = d.add(const Duration(days: 1));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('통계'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: '새로고침',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text('감정 분포 — ${df.format(_first)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            _EmotionBars(counts: counts, total: total),
            const SizedBox(height: 16),
            Text('연속 기록일', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 24,
              children: [
                Chip(label: Text('현재: ${currentStreak}일')),
                Chip(label: Text('최대(이번 달): ${maxStreak}일')),
                Chip(label: Text('이번 달 총 기록일: $total일')),
              ],
            ),
            const SizedBox(height: 24),
            const Text('팁: 더 긴 기간 통계를 원하면 월 선택 UI를 추가해 확장할 수 있어요.'),
          ],
        ),
      ),
    );
  }
}

class _EmotionBars extends StatelessWidget {
  final Map<int, int> counts;
  final int total;
  const _EmotionBars({required this.counts, required this.total});

  String _label(int i) {
    switch (i) {
      case 0: return '😞 매우나쁨';
      case 1: return '🙁 나쁨';
      case 2: return '😐 보통';
      case 3: return '🙂 좋음';
      case 4: return '🤩 매우좋음';
      default: return '$i';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (i) {
        final c = counts[i] ?? 0;
        final ratio = total == 0 ? 0.0 : c / total;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6.0),
          child: Row(
            children: [
              SizedBox(width: 100, child: Text(_label(i))),
              Expanded(child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(value: ratio, minHeight: 12),
              )),
              const SizedBox(width: 8),
              SizedBox(width: 36, child: Text('$c', textAlign: TextAlign.end)),
            ],
          ),
        );
      }),
    );
  }
}
