import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:diary_calendar_app/features/schedule/time_utils.dart';
import 'package:diary_calendar_app/features/schedule/schedule_provider.dart';
import 'package:diary_calendar_app/features/diary/diary_provider.dart';

/// 일정 추가/수정 다이얼로그
Future<void> openScheduleDialog(
  BuildContext context, {
  int? id,
  required DateTime date,
  int startMin = 540, // 09:00
  int endMin = 600, // 10:00
  String title = '',
  String memo = '',
}) async {
  // ✅ 다이어리도 이 날짜 기준으로 맞춰 두기
  context.read<DiaryProvider>().setDate(date);

  final formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController(text: title);
  final memoCtrl = TextEditingController(text: memo);
  int s = startMin;
  int e = endMin;

  final String dateLabel = DateFormat('yyyy-MM-dd').format(date);

  Future<void> pickTime(bool isStart) async {
    final initial = TimeOfDay(
      hour: (isStart ? s : e) ~/ 60,
      minute: (isStart ? s : e) % 60,
    );
    final res = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (res != null) {
      final mm = res.hour * 60 + res.minute;
      if (isStart) {
        s = mm;
        if (s > e) e = s + 30;
      } else {
        e = mm;
        if (e < s) s = e - 30;
      }
    }
  }

  await showDialog(
    context: context,
    builder: (ctx) {
      final diary = ctx.watch<DiaryProvider>();
      final currentDiary = diary.current;

      return AlertDialog(
        title: Text(id == null ? '일정 추가' : '일정 수정'),
        content: Form(
          key: formKey,
          child: SizedBox(
            width: 380,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      dateLabel,
                      style: Theme.of(ctx).textTheme.labelLarge,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ✅ 다이어리 요약 표시
                  if (currentDiary != null) ...[
                    Text(
                      '이 날짜의 다이어리',
                      style: Theme.of(ctx).textTheme.labelMedium,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Theme.of(ctx)
                            .colorScheme
                            .surfaceVariant
                            .withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentDiary.title,
                            style: Theme.of(ctx).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentDiary.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(ctx).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    Text(
                      '이 날짜에는 저장된 다이어리가 없습니다.',
                      style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                            color: Theme.of(ctx).hintColor,
                          ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 제목
                  TextFormField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: '제목'),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
                  ),
                  const SizedBox(height: 12),

                  // 시작/종료 시간
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await pickTime(true);
                            (ctx as Element).markNeedsBuild();
                          },
                          child: Text('시작 ${mmToHHmm(s)}'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            await pickTime(false);
                            (ctx as Element).markNeedsBuild();
                          },
                          child: Text('종료 ${mmToHHmm(e)}'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 메모
                  TextFormField(
                    controller: memoCtrl,
                    decoration: const InputDecoration(labelText: '메모(선택)'),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          if (id != null)
            TextButton(
              onPressed: () async {
                await context.read<ScheduleProvider>().deleteSchedule(id);
                if (context.mounted) Navigator.of(ctx).pop();
              },
              child: const Text(
                '삭제',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final sp = context.read<ScheduleProvider>();
                final trimmedTitle = titleCtrl.text.trim();
                final trimmedMemo = memoCtrl.text.trim();
                final memoValue =
                    trimmedMemo.isEmpty ? null : trimmedMemo;

                if (id == null) {
                  await sp.addSchedule(
                    date: sp.selectedDate,
                    startMin: s,
                    endMin: e,
                    title: trimmedTitle,
                    memo: memoValue,
                  );
                } else {
                  await sp.updateSchedule(
                    id: id,
                    date: sp.selectedDate,
                    startMin: s,
                    endMin: e,
                    title: trimmedTitle,
                    memo: memoValue,
                  );
                }
                if (context.mounted) Navigator.of(ctx).pop();
              }
            },
            child: const Text('저장'),
          ),
        ],
      );
    },
  );
}
