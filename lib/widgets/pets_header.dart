import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PetsHeader extends StatelessWidget {
  final int balance;
  const PetsHeader({super.key, required this.balance});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Mascotas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c.textPrimary)),
              Text('Selecciona tu compañero', style: TextStyle(fontSize: 14, color: c.textMuted)),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: c.statGreen, // Usa tu color adaptativo del ThemeExtension
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Text('⚡', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text('$balance coins',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF63E6BE) : const Color(0xFF2D7A4F), // Color de texto legible según el fondo
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}