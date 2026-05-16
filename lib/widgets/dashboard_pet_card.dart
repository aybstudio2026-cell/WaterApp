import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard_progress_ring.dart';

class PetCard extends StatelessWidget {
  final String? petImageUrl;
  final int totalMl;
  final int goalMl;
  final String statusText;
  final Color statusColor;

  const PetCard({
    super.key,
    required this.petImageUrl,
    required this.totalMl,
    required this.goalMl,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = goalMl > 0 ? (totalMl / goalMl).clamp(0.0, 1.0) : 0.0;

    // Calculamos los colores del anillo según el modo activo
    final trackColor = isDark ? const Color(0xFF2A2D3E) : const Color(0xFFE5E7EB);
    final ringColor = pct >= 0.8
        ? (isDark ? const Color(0xFF63E6BE) : const Color(0xFF2D7A4F))
        : pct >= 0.4
        ? AppTheme.primaryLight
        : const Color(0xFFEF4444); // Rojo más balanceado para pantallas oscuras

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: c.card, // Blanco en Light, Gris azulado en Dark
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Mascota
          SizedBox(
            height: 140,
            child: petImageUrl != null && petImageUrl!.isNotEmpty
                ? Image.network(
              petImageUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.pets, size: 80, color: AppTheme.primaryLight),
            )
                : const Icon(Icons.pets, size: 80, color: AppTheme.primaryLight),
          ),
          const SizedBox(height: 24),

          // Anillo de progreso
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: ProgressRing(
                    progress: pct,
                    trackColor: trackColor,
                    ringColor: ringColor,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${(pct * 100).toInt()}%',
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: c.textPrimary)),
                    Text('$totalMl / $goalMl ml',
                        style: TextStyle(
                            fontSize: 13, color: c.textMuted)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Text(statusText,
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}