import 'package:flutter/material.dart';

typedef OnPicked = void Function(int value);

/// 감정 선택 위젯(0~4). 추후 커스텀 아이콘/텍스트로 확장 가능.
class EmotionPicker extends StatelessWidget {
  final int value;
  final OnPicked onPicked;

  const EmotionPicker({super.key, required this.value, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final icons = const [
      Icons.sentiment_very_dissatisfied,
      Icons.sentiment_dissatisfied,
      Icons.sentiment_neutral,
      Icons.sentiment_satisfied,
      Icons.sentiment_very_satisfied,
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(5, (i) {
        final selected = value == i;
        return IconButton(
          onPressed: () => onPicked(i),
          icon: Icon(icons[i], size: selected ? 34 : 28),
          color: selected ? theme.colorScheme.primary : null,
          tooltip: '감정 $i',
        );
      }),
    );
  }
}
