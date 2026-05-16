import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsWeekChart extends StatelessWidget {
  final List<Map<String, dynamic>> weekData;
  final int goalMl;
  final String currentDayLabel;

  const StatsWeekChart({
    super.key,
    required this.goalMl,
    required this.weekData,
    required this.currentDayLabel,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final maxMl = weekData.fold<int>(
      goalMl,
          (m, d) => (d['ml'] as int) > m ? (d['ml'] as int) : m,
    );

    final emptyBarColor = isDark ? const Color(0xFF2A2D3E) : const Color(0xFFD1E4F5);

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
          Text('Consumo diario', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weekData.map((d) {
                final ml = d['ml'] as int;
                final pct = maxMl > 0 ? ml / maxMl : 0.0;
                final metGoal = ml >= goalMl;
                final isToday = d['day'] == currentDayLabel;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (ml > 0)
                          Text(
                            ml >= 1000 ? '${(ml / 1000).toStringAsFixed(1)}L' : '${ml}ml',
                            style: TextStyle(fontSize: 9, color: c.textMuted),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: pct > 0 ? 120 * pct : 4,
                          decoration: BoxDecoration(
                            color: metGoal
                                ? const Color(0xFF2D7A4F)
                                : isToday
                                ? AppTheme.primaryLight
                                : emptyBarColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(d['day'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: isToday ? AppTheme.primary : c.textMuted,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _legend(const Color(0xFF2D7A4F), 'Meta cumplida', c),
              const SizedBox(width: 16),
              _legend(AppTheme.primaryLight, 'Hoy', c),
              const SizedBox(width: 16),
              _legend(emptyBarColor, 'Sin meta', c),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label, AppColors c) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: c.textMuted)),
      ],
    );
  }
}