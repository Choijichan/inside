import 'package:flutter/material.dart';

class StatsPage extends StatelessWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('통계')),
      body: const Center(
        child: Text('감정 분포/연속 기록일 등은 후속 단계에서 구현됩니다.'),
      ),
    );
  }
}
