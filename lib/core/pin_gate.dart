import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pin_lock.dart';
import '../root_scaffold.dart'; // ✅ 여기로 수정

class PinGate extends StatelessWidget {
  const PinGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PinLockController>(
      builder: (context, pinLock, _) {
        if (pinLock.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (pinLock.hasPin) {
          return const RootScaffold(); // 이제 에러 안 남
        }

        return const RootScaffold();
      },
    );
  }
}
