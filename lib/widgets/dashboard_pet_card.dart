import 'package:flutter/material.dart';
import 'dashboard_progress_ring.dart';

class PetCard extends StatelessWidget {
  final String? petImageUrl;
  final int totalMl;
  final int goalMl;
  final String statusText;
  final Color statusColor;

  const PetCard({
    super.key,
    required this.petImageUrl,
    required this.totalMl,
    required this.goalMl,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final pct = goalMl > 0 ? (totalMl / goalMl).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          // Mascota
          SizedBox(
            height: 140,
            child: petImageUrl != null && petImageUrl!.isNotEmpty
                ? Image.network(
              petImageUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
              const Icon(Icons.pets, size: 80, color: Color(0xFF4A90D9)),
            )
                : const Icon(Icons.pets, size: 80, color: Color(0xFF4A90D9)),
          ),
          const SizedBox(height: 24),

          // Anillo de progreso
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(160, 160),
                  painter: ProgressRing(progress: pct),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('${(pct * 100).toInt()}%',
                        style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A2E6E))),
                    Text('$totalMl / $goalMl ml',
                        style: const TextStyle(
                            fontSize: 13, color: Color(0xFF6B7280))),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Text(statusText,
              style: TextStyle(
                fontSize: 14,
                color: statusColor,
                fontWeight: FontWeight.w500,
              )),
        ],
      ),
    );
  }
}