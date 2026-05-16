import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AchievementsListCard extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final bool isUnlocked;

  const AchievementsListCard({
    super.key,
    required this.achievement,
    required this.isUnlocked,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? c.card : c.card2, // Cambia automáticamente de color de fondo
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? AppTheme.primary.withValues(alpha: 0.3)
              : c.border,
        ),
        boxShadow: isUnlocked
            ? [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 3))]
            : [],
      ),
      child: Row(
        children: [
          // Contenedor del Ícono
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: isUnlocked ? c.statBlue : c.border, // Adaptación cromática según bloqueo
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                isUnlocked ? achievement['icon'] as String : '🔒',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Textos informativos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement['title'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isUnlocked ? c.textPrimary : c.textMuted,
                    )),
                const SizedBox(height: 3),
                Text(achievement['desc'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: isUnlocked ? c.textSecondary : c.textMuted.withValues(alpha: 0.7),
                    )),
              ],
            ),
          ),

          // Badge Check de Desbloqueado
          if (isUnlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: c.statGreen,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('✓',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF63E6BE) : const Color(0xFF2D7A4F),
                    fontWeight: FontWeight.bold,
                  )),
            ),
        ],
      ),
    );
  }
}