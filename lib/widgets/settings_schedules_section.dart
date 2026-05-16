import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsSchedulesSection extends StatelessWidget {
  final TimeOfDay wakeTime;
  final TimeOfDay sleepTime;
  final VoidCallback onWakeTimeTap;
  final VoidCallback onSleepTimeTap;

  const SettingsSchedulesSection({
    super.key,
    required this.wakeTime,
    required this.sleepTime,
    required this.onWakeTimeTap,
    required this.onSleepTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Horarios de recordatorio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textMuted, letterSpacing: 0.5)),
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
              _timeRow(context, 'Hora de despertar', wakeTime, onWakeTimeTap, c),
              Divider(color: c.border, height: 1),
              _timeRow(context, 'Hora de dormir', sleepTime, onSleepTimeTap, c),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeRow(BuildContext context, String label, TimeOfDay time, VoidCallback onTap, AppColors c) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.access_time_outlined, size: 18, color: Color(0xFF9CA3AF)),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14, color: c.textSecondary)),
            const Spacer(),
            Text(time.format(context), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF4A90D9))),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: c.textMuted),
          ],
        ),
      ),
    );
  }
}