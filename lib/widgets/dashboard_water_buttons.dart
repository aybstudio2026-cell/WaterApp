import 'package:flutter/material.dart';

class WaterButtonsSection extends StatelessWidget {
  final Function(int) onLogWater;

  const WaterButtonsSection({
    super.key,
    required this.onLogWater,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Registrar consumo',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A2E6E))),
        const SizedBox(height: 12),
        Row(
          children: [
            _WaterButton(
              label: '+250 ml',
              ml: 250,
              bg: const Color(0xFFD6E4FF),
              fg: const Color(0xFF2D5BE3),
              onTap: () => onLogWater(250),
            ),
            const SizedBox(width: 10),
            _WaterButton(
              label: '+500 ml',
              ml: 500,
              bg: const Color(0xFF4A90D9),
              fg: Colors.white,
              onTap: () => onLogWater(500),
            ),
            const SizedBox(width: 10),
            _WaterButton(
              label: '+1 L',
              ml: 1000,
              bg: const Color(0xFF1A2E6E),
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
  final int ml;
  final Color bg;
  final Color fg;
  final VoidCallback onTap;

  const _WaterButton({
    required this.label,
    required this.ml,
    required this.bg,
    required this.fg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
                color: bg.withOpacity(0.4),
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