import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../core/notify.dart';
import 'dart:io' show Platform;

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  TimeOfDay _reminderTime = const TimeOfDay(hour: 21, minute: 0);
  bool _reminderOn = false;

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: ListView(
        children: [
          const ListTile(
            title: Text('개인화'),
            dense: true,
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('테마'),
            subtitle: Text({
              AppThemeMode.system: '시스템',
              AppThemeMode.light: '라이트',
              AppThemeMode.dark: '다크',
            }[themeCtrl.mode]!),
            trailing: DropdownButton<AppThemeMode>(
              value: themeCtrl.mode,
              onChanged: (m) => themeCtrl.setMode(m!),
              items: const [
                DropdownMenuItem(value: AppThemeMode.system, child: Text('시스템')),
                DropdownMenuItem(value: AppThemeMode.light, child: Text('라이트')),
                DropdownMenuItem(value: AppThemeMode.dark, child: Text('다크')),
              ],
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text('알림'),
            dense: true,
          ),
          SwitchListTile(
            title: const Text('매일 기록 알림'),
            subtitle: Text('시간: ${''}'),
            value: _reminderOn,
            onChanged: (v) async {
              setState(() => _reminderOn = v);
              if (v) {
                await NotificationService().scheduleDailyReminder(hour: _reminderTime.hour, minute: _reminderTime.minute);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('매일 알림이 설정되었습니다.')));
              } else {
                await NotificationService().cancelDailyReminder();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('매일 알림이 해제되었습니다.')));
              }
            },
            secondary: const Icon(Icons.notifications_active_outlined),
          ),
          ListTile(
            leading: const SizedBox(width: 24),
            title: const Text('알림 시간 설정'),
            subtitle: Text(DateFormat('HH:mm').format(DateTime(0,1,1,_reminderTime.hour,_reminderTime.minute))),
            onTap: () async {
              final picked = await showTimePicker(context: context, initialTime: _reminderTime);
              if (picked != null) {
                setState(() => _reminderTime = picked);
                if (_reminderOn) {
                  await NotificationService().scheduleDailyReminder(hour: _reminderTime.hour, minute: _reminderTime.minute);
                }
              }
            },
            trailing: const Icon(Icons.schedule_outlined),
          ),
          if (Platform.isAndroid)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              child: Text('※ Android 13 이상에서는 알림 권한 허용이 필요할 수 있습니다.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
        ],
      ),
    );
  }
}
