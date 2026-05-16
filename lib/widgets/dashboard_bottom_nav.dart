import 'package:flutter/material.dart';
import '../theme/app_theme.dart'; // Importante para acceder a AppColors y AppTheme

class DashboardBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabChanged;

  const DashboardBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      (Icons.water_drop_outlined, 'Inicio'),
      (Icons.bar_chart_outlined, 'Stats'),
      (Icons.pets_outlined, 'Mascotas'),
      (Icons.emoji_events_outlined, 'Logros'),
      (Icons.settings_outlined, 'Ajustes'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: c.card, // Cambia automáticamente entre blanco y gris oscuro
        boxShadow: [
          BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, -2)),
        ],
        border: Border(
          top: BorderSide(color: c.border, width: isDark ? 0.5 : 0.0), // Sutil línea superior en modo oscuro
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (i) {
              final active = i == selectedIndex;
              return GestureDetector(
                onTap: () => onTabChanged(i),
                behavior: HitTestBehavior.opaque, // Amplía la zona interactiva del toque
                child: SizedBox(
                  width: 60, // Da un ancho fijo a cada pestaña para alinear el toque
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].$1,
                          size: 24,
                          color: active
                              ? AppTheme.primary // Azul dinámico de la marca
                              : c.textMuted),     // Gris adaptativo
                      const SizedBox(height: 4),
                      Text(items[i].$2,
                          style: TextStyle(
                            fontSize: 10,
                            color: active
                                ? AppTheme.primary
                                : c.textMuted,
                            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                          )),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}