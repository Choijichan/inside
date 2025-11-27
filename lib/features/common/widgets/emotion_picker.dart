import 'package:flutter/material.dart';

/// 감정 선택 위젯
/// - value: 현재 선택된 감정 (1~5)
/// - onSelected: 감정이 선택될 때 호출
class EmotionPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onSelected;

  const EmotionPicker({
    super.key,
    required this.value,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    // 1~5 감정 이모지/라벨 정의
    const emotions = [
      '😭', // 1
      '☹️', // 2
      '😐', // 3
      '😊', // 4
      '🤩', // 5
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(emotions.length, (index) {
        final emoIndex = index + 1;
        final selected = (emoIndex == value);

        return GestureDetector(
          onTap: () => onSelected(emoIndex),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary.withOpacity(0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  emotions[index],
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(height: 4),
                Icon(
                  selected ? Icons.radio_button_checked : Icons.circle_outlined,
                  size: 16,
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).hintColor,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
