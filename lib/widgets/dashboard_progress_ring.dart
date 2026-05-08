import 'package:flutter/material.dart';
import 'dart:math' as math;

class ProgressRing extends CustomPainter {
  final double progress;
  const ProgressRing({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 16) / 2;
    const stroke = 12.0;

    // Fondo gris
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = const Color(0xFFE5E7EB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    // Progreso con color según estado
    final color = progress >= 0.8
        ? const Color(0xFF2D7A4F)
        : progress >= 0.4
        ? const Color(0xFF4A90D9)
        : const Color(0xFFDC2626);

    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(ProgressRing old) => old.progress != progress;
}