import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsHydrationSection extends StatelessWidget {
  final double weightKg;
  final String activityLevel;
  final ValueChanged<double> onWeightChanged;
  final ValueChanged<String> onActivityChanged;

  const SettingsHydrationSection({
    super.key,
    required this.weightKg,
    required this.activityLevel,
    required this.onWeightChanged,
    required this.onActivityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Perfil de hidratación', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textMuted, letterSpacing: 0.5)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: c.card,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Peso', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textSecondary)),
                  Text('${weightKg.toInt()} kg', style: const TextStyle(fontSize: 14, color: Color(0xFF4A90D9), fontWeight: FontWeight.w600)),
                ],
              ),
              Slider(
                value: weightKg, min: 40, max: 150, divisions: 110,
                activeColor: const Color(0xFF4A90D9),
                onChanged: onWeightChanged,
              ),
              Divider(color: c.border),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Nivel de actividad', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: c.textSecondary)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _activityBtn('low', 'Bajo', '🧘', c),
                  const SizedBox(width: 8),
                  _activityBtn('medium', 'Medio', '🚶', c),
                  const SizedBox(width: 8),
                  _activityBtn('high', 'Alto', '🏃', c),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _activityBtn(String value, String label, String emoji, AppColors c) {
    final isSelected = activityLevel == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onActivityChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF2D5BE3) : c.card2,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 20)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : c.textSecondary,
              )),
            ],
          ),
        ),
      ),
    );
  }
}