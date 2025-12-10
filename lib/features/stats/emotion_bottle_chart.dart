import 'dart:math';
import 'package:flutter/material.dart';

class EmotionBead {
  final Color color;
  EmotionBead(this.color);
}

class EmotionBottleChart extends StatelessWidget {
  final List<EmotionBead> beads;
  final Color bottleColor;
  final Color bottleFillColor;

  const EmotionBottleChart({
    super.key,
    required this.beads,
    this.bottleColor = const Color(0xFFCCCCCC),
    this.bottleFillColor = const Color(0x11FF9800),
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 5,
      child: CustomPaint(
        painter: _BottlePainter(
          beads: beads,
          bottleColor: bottleColor,
          bottleFillColor: bottleFillColor,
        ),
      ),
    );
  }
}

class _BottlePainter extends CustomPainter {
  final List<EmotionBead> beads;
  final Color bottleColor;
  final Color bottleFillColor;

  _BottlePainter({
    required this.beads,
    required this.bottleColor,
    required this.bottleFillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double neckHeight = size.height * 0.18;
    final double neckWidth = size.width * 0.28;
    final double bodyWidth = size.width * 0.7;
    final double bodyRadius = size.width * 0.18;
    final double bottomMargin = size.height * 0.06;

    final Rect bodyRect = Rect.fromLTWH(
      (size.width - bodyWidth) / 2,
      neckHeight,
      bodyWidth,
      size.height - neckHeight - bottomMargin,
    );
    final RRect bodyRRect = RRect.fromRectAndRadius(
      bodyRect,
      Radius.circular(bodyRadius),
    );

    final Rect neckRect = Rect.fromLTWH(
      (size.width - neckWidth) / 2,
      neckHeight * 0.1,
      neckWidth,
      neckHeight * 0.7,
    );

    final Rect capRect = Rect.fromLTWH(
      neckRect.left - neckWidth * 0.15,
      0,
      neckRect.width * 1.3,
      neckHeight * 0.18,
    );

    final Paint fillPaint = Paint()
      ..color = bottleFillColor
      ..style = PaintingStyle.fill;
    canvas.drawRRect(bodyRRect, fillPaint);

    final Paint strokePaint = Paint()
      ..color = bottleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(bodyRRect, strokePaint);
    canvas.drawRect(neckRect, strokePaint);
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, Radius.circular(neckHeight * 0.1)),
      strokePaint,
    );

    _drawBeads(canvas, bodyRect.deflate(6));
  }

  void _drawBeads(Canvas canvas, Rect area) {
    if (beads.isEmpty) return;

    final int count = beads.length;

    final double maxRadius = min(area.width, area.height) / 18;
    final double radius = maxRadius.clamp(4, 12);
    const double spacing = 2;

    final int cols = max(1, (area.width / (radius * 2 + spacing)).floor());
    final int rows = max(1, (count / cols).ceil());

    final random = Random(count);

    for (int i = 0; i < count; i++) {
      final bead = beads[i];

      final int row = i ~/ cols;
      final int col = i % cols;

      final double x = area.left +
          radius +
          col * (radius * 2 + spacing) +
          (random.nextDouble() - 0.5) * radius * 0.5;

      final double y = area.bottom -
          radius -
          row * (radius * 2 + spacing) +
          (random.nextDouble() - 0.5) * radius * 0.5;

      final Paint beadPaint = Paint()
        ..color = bead.color
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), radius, beadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BottlePainter oldDelegate) {
    return oldDelegate.beads != beads ||
           oldDelegate.bottleColor != bottleColor ||
           oldDelegate.bottleFillColor != bottleFillColor;
  }
}
