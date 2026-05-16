import 'package:flutter/material.dart';
import 'dart:math' as math;

class ProgressRing extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color ringColor;

  const ProgressRing({
    required this.progress,
    required this.trackColor,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = (size.width - 16) / 2;
    const stroke = 12.0;

    // Fondo del anillo
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      0,
      math.pi * 2,
      false,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );

    if (progress <= 0) return;

    // Arco de progreso inyectado
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: radius),
      -math.pi / 2,
      math.pi * 2 * progress,
      false,
      Paint()
        ..color = ringColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(ProgressRing old) =>
      old.progress != progress ||
          old.trackColor != trackColor ||
          old.ringColor != ringColor;
}