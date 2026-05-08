import 'package:flutter/material.dart';

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
    final items = [
      (Icons.water_drop_outlined, 'Inicio'),
      (Icons.bar_chart_outlined, 'Stats'),
      (Icons.pets_outlined, 'Mascotas'),
      (Icons.emoji_events_outlined, 'Logros'),
      (Icons.settings_outlined, 'Ajustes'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, -2)),
        ],
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(items[i].$1,
                        size: 24,
                        color: active
                            ? const Color(0xFF2D5BE3)
                            : const Color(0xFF9CA3AF)),
                    const SizedBox(height: 4),
                    Text(items[i].$2,
                        style: TextStyle(
                          fontSize: 10,
                          color: active
                              ? const Color(0xFF2D5BE3)
                              : const Color(0xFF9CA3AF),
                          fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                        )),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}