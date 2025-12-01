import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import '../../data/drift/drift_database.dart';
import 'emotion_bottle_chart.dart';

/// 감정 인덱스(1~5) -> 색상 매핑
Color _emotionColor(int emotion) {
  switch (emotion) {
    case 1:
      return const Color(0xFFEF5350); // 매우 나쁨
    case 2:
      return const Color(0xFFFFA726); // 나쁨
    case 3:
      return const Color(0xFF4DD0E1); // 보통
    case 4:
      return const Color.fromARGB(255, 255, 136, 0); // 좋음
    case 5:
      return const Color.fromARGB(255, 255, 0, 0); // 매우 좋음
    default:
      return Colors.grey; // 혹시 1~5 범위 밖 값이 들어오면 회색
  }
}


/// 감정 카운트 맵 -> 병 안에 들어갈 구슬 리스트로 변환 (전역 함수)
List<EmotionBead> _buildBeadsFromCounts(Map<int, int> counts) {
  final beads = <EmotionBead>[];
  counts.forEach((emotion, count) {
    final color = _emotionColor(emotion);
    for (int i = 0; i < count; i++) {
      beads.add(EmotionBead(color));
    }
  });
  return beads;
}

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

    // 감정 카운트
    final Map<int, int> counts = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0};
    for (final r in _rows) {
      counts[r.emotion] = (counts[r.emotion] ?? 0) + 1;
    }
    final total = _rows.length;

    // Streak 계산(이번 달 기준)
    final days = _rows.map((e) => e.date).toSet();
    int currentStreak = 0;
    int maxStreak = 0;
    final today = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

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
            Text(
              '감정 분포 — ${df.format(_first)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            // 🧡 감정 병 차트
            Center(
              child: EmotionBottleChart(
                beads: _buildBeadsFromCounts(counts),
              ),
            ),
            const SizedBox(height: 16),

            // 기존 바 차트
            _EmotionBars(counts: counts, total: total),
            const SizedBox(height: 16),

            Text(
              '연속 기록일',
              style: Theme.of(context).textTheme.titleMedium,
            ),
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
      case 0:
        return '😞 매우나쁨';
      case 1:
        return '🙁 나쁨';
      case 2:
        return '😐 보통';
      case 3:
        return '🙂 좋음';
      case 4:
        return '🤩 매우좋음';
      default:
        return '$i';
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
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 36,
                child: Text(
                  '$c',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
