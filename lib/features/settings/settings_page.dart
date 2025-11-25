import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../core/notification_service.dart';
import '../../core/pin_lock.dart';

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
          hour: _reminderTime.hour,
          minute: _reminderTime.minute,
        );
      }
    }
  }

  Future<void> _openPinDialog() async {
    final pinLock = context.read<PinLockController>();

    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _PinEditDialog(pinLock: pinLock),
    );

    if (changed == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN이 설정/변경되었습니다.')),
      );
      setState(() {}); // 상태 텍스트 업데이트
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeCtrl = context.watch<ThemeController>();
    final pinLock = context.watch<PinLockController>();

    String pinStatusText =
        pinLock.hasPin ? 'PIN 잠금 사용 중' : 'PIN 잠금 사용 안 함';

    return Scaffold(
      appBar: AppBar(
        title: const Text('설정'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '테마 설정',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          RadioListTile<AppThemeMode>(
            title: const Text('시스템 설정 따르기'),
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

          // 🔔 알림 설정
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '일기 알림',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
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
            title: const Text('알림 시간 변경'),
            subtitle: Text('현재: ${_reminderTime.format(context)}'),
            onTap: _pickTime,
          ),
          const SizedBox(height: 8),
          const Divider(),

          // 🔐 PIN 잠금 설정
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '보안',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.lock_outline),
            title: const Text('PIN 잠금'),
            subtitle: Text(pinStatusText),
            trailing: TextButton(
              onPressed: _openPinDialog,
              child: Text(pinLock.hasPin ? '변경' : '설정'),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'PIN은 이 기기에만 저장되며, 앱 실행 시 잠금 화면에서 사용됩니다.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// PIN 설정/변경용 다이얼로그
class _PinEditDialog extends StatefulWidget {
  final PinLockController pinLock;

  const _PinEditDialog({required this.pinLock});

  @override
  State<_PinEditDialog> createState() => _PinEditDialogState();
}

class _PinEditDialogState extends State<_PinEditDialog> {
  final _currentPin = TextEditingController();
  final _newPin = TextEditingController();
  final _confirmPin = TextEditingController();
  String? _error;

  bool get _hasPin => widget.pinLock.hasPin;

  void _submit() async {
    final current = _currentPin.text.trim();
    final newPin = _newPin.text.trim();
    final confirm = _confirmPin.text.trim();

    if (_hasPin) {
      if (!widget.pinLock.verify(current)) {
        setState(() {
          _error = '현재 PIN이 올바르지 않습니다.';
        });
        return;
      }
    }

    if (newPin.length < 4) {
      setState(() {
        _error = '새 PIN은 최소 4자리 숫자로 입력하세요.';
      });
      return;
    }

    if (newPin != confirm) {
      setState(() {
        _error = '새 PIN과 확인 PIN이 일치하지 않습니다.';
      });
      return;
    }

    await widget.pinLock.setPin(newPin);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_hasPin ? 'PIN 변경' : 'PIN 설정'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_hasPin) ...[
              TextField(
                controller: _currentPin,
                obscureText: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: '현재 PIN',
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _newPin,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '새 PIN (최소 4자리)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPin,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '새 PIN 확인',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('저장'),
        ),
      ],
    );
  }
}
