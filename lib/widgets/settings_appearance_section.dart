import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';

class SettingsAppearanceSection extends StatelessWidget {
  const SettingsAppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Apariencia', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    themeService.isDark ? Icons.dark_mode : Icons.light_mode,
                    size: 20, color: const Color(0xFF9CA3AF),
                  ),
                  const SizedBox(width: 12),
                  Text('Modo oscuro', style: TextStyle(fontSize: 14, color: c.textSecondary)),
                ],
              ),
              Switch(
                value: themeService.isDark,
                onChanged: (_) => themeService.toggle(),
                activeColor: const Color(0xFF2D5BE3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}