import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pin_lock.dart';
import '../features/lock/lock_screen.dart';
import '../main.dart'; // RootScaffold

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
          return const LockScreen();
        }

        return const RootScaffold();
      },
    );
  }
}
