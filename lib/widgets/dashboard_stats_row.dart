import 'package:flutter/material.dart';

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
    return Row(
      children: [
        _StatCard(
          label: 'Meta diaria',
          value: '$goalMl ml',
          icon: Icons.flag_outlined,
          bg: const Color(0xFFD6E4FF),
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Hoy',
          value: '$totalMl ml',
          icon: Icons.water_drop_outlined,
          bg: const Color(0xFFD6F5E3),
        ),
        const SizedBox(width: 12),
        _StatCard(
          label: 'Racha',
          value: '$streak días',
          icon: Icons.local_fire_department_outlined,
          bg: const Color(0xFFFFEDD5),
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
            Icon(icon, size: 20, color: const Color(0xFF1A2E6E)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A2E6E))),
            Text(label,
                style:
                const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }
}