import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsDayList extends StatelessWidget {
  final List<Map<String, dynamic>> weekData;
  final int goalMl;

  const StatsDayList({
    super.key,
    required this.weekData,
    required this.goalMl,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Detalle por día', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 16),
          ...weekData.reversed.map((d) {
            final ml = d['ml'] as int;
            final metGoal = ml >= goalMl;
            final pct = goalMl > 0 ? (ml / goalMl).clamp(0.0, 1.0) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(d['day'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textSecondary)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: c.border,
                        valueColor: AlwaysStoppedAnimation(metGoal ? const Color(0xFF2D7A4F) : AppTheme.primaryLight),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 32,
                    child: Text(metGoal ? '✅' : ml > 0 ? '🔄' : '—', textAlign: TextAlign.center),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}