
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/notification_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (picked != null) {
      setState(() => _reminderTime = picked);
      if (_reminderEnabled) {
        await NotificationService().scheduleDailyReminder(
          hour: picked.hour,
          minute: picked.minute,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          const ListTile(
            title: Text('테마 설정'),
            subtitle: Text('시스템/라이트/다크 모드 선택'),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('시스템 기본값'),
            value: AppThemeMode.system,
            groupValue: themeCtrl.mode,
            onChanged: (v) {
              if (v != null) themeCtrl.setMode(v);
            },
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('라이트 모드'),
            value: AppThemeMode.light,
            groupValue: themeCtrl.mode,
            onChanged: (v) {
              if (v != null) themeCtrl.setMode(v);
            },
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('다크 모드'),
            value: AppThemeMode.dark,
            groupValue: themeCtrl.mode,
            onChanged: (v) {
              if (v != null) themeCtrl.setMode(v);
            },
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('하루 일기 알림 받기'),
            subtitle: Text(
              _reminderEnabled
                  ? '매일 ${_reminderTime.format(context)}에 알림'
                  : '알림 사용 안 함',
            ),
            value: _reminderEnabled,
            onChanged: (value) async {
              setState(() => _reminderEnabled = value);
              if (value) {
                await NotificationService().scheduleDailyReminder(
                  hour: _reminderTime.hour,
                  minute: _reminderTime.minute,
                );
              } else {
                await NotificationService().cancelDailyReminder();
              }
            },
          ),
          ListTile(
            title: const Text('알림 시간 설정'),
            subtitle: Text('현재 설정: ${_reminderTime.format(context)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _reminderEnabled ? _pickTime : null,
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '알림은 flutter_local_notifications를 사용해 로컬에서만 동작합니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
