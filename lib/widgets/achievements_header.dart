import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AchievementsHeader extends StatelessWidget {
  final int unlockedCount;
  final int totalCount;

  const AchievementsHeader({
    super.key,
    required this.unlockedCount,
    required this.totalCount,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final pct = totalCount == 0 ? 0.0 : unlockedCount / totalCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Logros',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c.textPrimary)),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 8,
              backgroundColor: c.border, // Track adaptativo al modo oscuro
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}