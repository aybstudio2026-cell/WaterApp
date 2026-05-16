import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsSummaryCards extends StatelessWidget {
  final int avgMl;
  final int daysMet;
  final int bestStreak;

  const StatsSummaryCards({
    super.key,
    required this.avgMl,
    required this.daysMet,
    required this.bestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Row(
      children: [
        _summaryCard('Promedio', '$avgMl ml', Icons.water_drop_outlined, c.statBlue, c),
        const SizedBox(width: 12),
        _summaryCard('Meta cumplida', '$daysMet / 7 d', Icons.check_circle_outline, c.statGreen, c),
        const SizedBox(width: 12),
        _summaryCard('Mejor racha', '$bestStreak días', Icons.local_fire_department_outlined, c.statOrange, c),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color bg, AppColors c) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: c.textPrimary),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: c.textPrimary)),
            Text(label, style: TextStyle(fontSize: 10, color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}