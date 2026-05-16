import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WaterButtonsSection extends StatelessWidget {
  final Function(int) onLogWater;

  const WaterButtonsSection({
    super.key,
    required this.onLogWater,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Registrar consumo',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: c.textPrimary)),
        const SizedBox(height: 12),
        Row(
          children: [
            // Botón +250 ml
            _WaterButton(
              label: '+250 ml',
              bg: c.statBlue,
              fg: isDark ? Colors.white : AppTheme.primary,
              onTap: () => onLogWater(250),
            ),
            const SizedBox(width: 10),
            // Botón +500 ml
            _WaterButton(
              label: '+500 ml',
              bg: AppTheme.primaryLight,
              fg: Colors.white,
              onTap: () => onLogWater(500),
            ),
            const SizedBox(width: 10),
            // Botón +1 L (Se adapta dinámicamente al modo oscuro)
            _WaterButton(
              label: '+1 L',
              bg: isDark ? AppTheme.primary : const Color(0xFF1A2E6E),
              fg: Colors.white,
              onTap: () => onLogWater(1000),
            ),
          ],
        ),
      ],
    );
  }
}

class _WaterButton extends StatelessWidget {
  final String label;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _WaterButton({
    required this.label,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: isDark ? 0.1 : 0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Center(
            child: Text(label,
                style: TextStyle(
                    color: fg, fontSize: 15, fontWeight: FontWeight.w600)),
          ),
        ),
      ),
    );
  }
}