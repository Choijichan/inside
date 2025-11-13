import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../schedule/time_utils.dart';
import 'schedule_provider.dart';

/// 일정 추가/수정 다이얼로그
Future<void> openScheduleDialog(BuildContext context, {
  int? id,
  required DateTime date,
  int startMin = 540, // 09:00
  int endMin = 600,   // 10:00
  String title = '',
  String memo = '',
}) async {
  final formKey = GlobalKey<FormState>();
  final titleCtrl = TextEditingController(text: title);
  final memoCtrl = TextEditingController(text: memo);
  int s = startMin;
  int e = endMin;

  String dateLabel = DateFormat('yyyy-MM-dd').format(date);

  Future<void> pickTime(bool isStart) async {
    final initial = TimeOfDay(hour: (isStart ? s : e) ~/ 60, minute: (isStart ? s : e) % 60);
    final res = await showTimePicker(context: context, initialTime: initial);
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
    builder: (ctx) => AlertDialog(
      title: Text(id == null ? '일정 추가' : '일정 수정'),
      content: Form(
        key: formKey,
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(alignment: Alignment.centerLeft, child: Text(dateLabel, style: Theme.of(ctx).textTheme.labelLarge)),
              const SizedBox(height: 12),
              TextFormField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: '제목'),
                validator: (v) => (v == null || v.trim().isEmpty) ? '제목을 입력하세요' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: OutlinedButton(
                    onPressed: () async { await pickTime(true); (ctx as Element).markNeedsBuild(); },
                    child: Text('시작 ${mmToHHmm(s)}'),
                  )),
                  const SizedBox(width: 8),
                  Expanded(child: OutlinedButton(
                    onPressed: () async { await pickTime(false); (ctx as Element).markNeedsBuild(); },
                    child: Text('종료 ${mmToHHmm(e)}'),
                  )),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: memoCtrl,
                decoration: const InputDecoration(labelText: '메모(선택)'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (id != null) TextButton(
          onPressed: () async {
            await context.read<ScheduleProvider>().deleteSchedule(id);
            if (context.mounted) Navigator.of(ctx).pop();
          },
          child: const Text('삭제', style: TextStyle(color: Colors.redAccent)),
        ),
        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('취소')),
        FilledButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              final sp = context.read<ScheduleProvider>();
              if (id == null) {
                await sp.addSchedule(date: sp.selectedDate, startMin: s, endMin: e, title: titleCtrl.text.trim(), memo: memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim());
              } else {
                await sp.updateSchedule(id: id, date: sp.selectedDate, startMin: s, endMin: e, title: titleCtrl.text.trim(), memo: memoCtrl.text.trim().isEmpty ? null : memoCtrl.text.trim());
              }
              if (context.mounted) Navigator.of(ctx).pop();
            }
          },
          child: const Text('저장'),
        ),
      ],
    ),
  );
}
