import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'pin_lock.dart';
import '../root_scaffold.dart';
import '../features/lock/lock_screen.dart'; //  PIN 입력 화면

class PinGate extends StatelessWidget {
  const PinGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PinLockController>(
      builder: (context, pinLock, _) {
        // 1) 아직 SharedPreferences에서 PIN 불러오는 중이면 로딩
        if (pinLock.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // 2) PIN이 설정되어 있으면 → 앱 시작 시 무조건 PIN 입력 화면
        if (pinLock.hasPin) {
          return const LockScreen();
        }

        // 3) PIN이 아직 설정 안 돼 있으면 → 그냥 메인 화면 진입
        return const RootScaffold();
      },
    );
  }
}
