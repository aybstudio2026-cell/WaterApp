import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsAccountSection extends StatelessWidget {
  final String email;
  final int balance;
  final bool isPremium;

  const SettingsAccountSection({
    super.key,
    required this.email,
    required this.balance,
    required this.isPremium,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cuenta', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: c.textMuted, letterSpacing: 0.5)),
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
              _infoRow(Icons.email_outlined, 'Correo', email, c.textSecondary, c.textPrimary),
              Divider(color: c.border, height: 1),
              _infoRow(Icons.bolt_outlined, 'Balance', '$balance coins', c.textSecondary, c.textPrimary),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color labelColor, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: labelColor)),
          const Spacer(),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor)),
        ],
      ),
    );
  }
}