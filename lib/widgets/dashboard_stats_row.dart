import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatsRow extends StatelessWidget {
  final int goalMl;
  final int totalMl;
  final int streak;

  const StatsRow({
    super.key,
    required this.goalMl,
    required this.totalMl,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Row(
      children: [
        _StatCard(
          label: 'Meta diaria',
          value: '$goalMl ml',
          icon: Icons.flag_outlined,
          bg: c.statBlue, // Azul adaptativo
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Hoy',
          value: '$totalMl ml',
          icon: Icons.water_drop_outlined,
          bg: c.statGreen, // Verde adaptativo
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Racha',
          value: '$streak días',
          icon: Icons.local_fire_department_outlined,
          bg: c.statOrange, // Naranja adaptativo
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color bg;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: c.textPrimary),
            const SizedBox(height: 8),
            Text(value,
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: c.textPrimary)),
            Text(label,
                style: TextStyle(fontSize: 11, color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}