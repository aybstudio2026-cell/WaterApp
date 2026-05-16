import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Importante para acceder a AppColors y AppTheme

class DashboardHeader extends StatelessWidget {
  final int streak;
  final VoidCallback onLogout;

  const DashboardHeader({
    super.key,
    required this.streak,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context); // Colores dinámicos del ThemeExtension
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Buenos días'
        : hour < 18
        ? 'Buenas tardes'
        : 'Buenas noches';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      color: c.bg, // Fondo dinámico de la app
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(greeting,
                  style: TextStyle(fontSize: 13, color: c.textMuted)),
              Text('WaterApp',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: c.textPrimary)),
            ],
          ),
          Row(
            children: [
              // Badge racha
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: c.statOrange, // Naranja adaptativo (claro u oscuro de fondo)
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text('$streak días',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFFF8A65) : const Color(0xFFEA580C))), // Texto legible según modo
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Botón logout
              GestureDetector(
                onTap: onLogout,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: c.card, // Fondo dinámico del botón
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: c.border), // Borde adaptativo
                  ),
                  child: Icon(Icons.logout,
                      size: 18, color: c.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}