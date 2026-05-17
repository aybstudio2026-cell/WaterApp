import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AchievementsListCard extends StatelessWidget {
  final Map<String, dynamic> achievement;
  final bool isUnlocked;
  final bool isClaimed;
  final VoidCallback? onClaimTap;

  const AchievementsListCard({
    super.key,
    required this.achievement,
    required this.isUnlocked,
    required this.isClaimed,
    required this.onClaimTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Si está bloqueado, le damos una opacidad sutil para diferenciarlo
    final double cardOpacity = isUnlocked ? 1.0 : 0.5;

    return Opacity(
      opacity: cardOpacity,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.card, // Blanco en Light, Gris azulado en Dark
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnlocked
                ? (isClaimed ? c.border : AppTheme.primaryLight.withValues(alpha: 0.4))
                : c.border,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // Ícono del logro
            Text(
              achievement['icon'] ?? '🏆',
              style: const TextStyle(fontSize: 30),
            ),
            const SizedBox(width: 16),

            // Textos Informativos
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    achievement['title'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    achievement['desc'] ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),

            // Botón de Acción Dinámico
            _buildActionWidget(context, c, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildActionWidget(BuildContext context, AppColors c, bool isDark) {
    // 1. Si está bloqueado: Candado
    if (!isUnlocked) {
      return Icon(Icons.lock_outline, color: c.textMuted, size: 20);
    }

    // 2. Si ya cobró la recompensa: Badge de éxito
    if (isClaimed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2D7A4F).withValues(alpha: 0.2)
              : const Color(0xFFD6F5E3),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Cobrado ✓',
          style: TextStyle(
            color: isDark ? const Color(0xFF63E6BE) : const Color(0xFF2D7A4F),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // 3. Logro listo para reclamar monedas (Botón interactivo)
    return ElevatedButton(
      onPressed: onClaimTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2D5BE3),
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('+10', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          SizedBox(width: 3),
          Icon(Icons.monetization_on, size: 14, color: Colors.amber),
        ],
      ),
    );
  }
}