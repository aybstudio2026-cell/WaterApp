import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../theme/app_theme.dart';
import '../services/cache_service.dart';

class PetsGridCard extends StatelessWidget {
  final Map<String, dynamic> pet;
  final bool isOwned;
  final bool isActive;
  final bool isBuying;
  final VoidCallback onSelect;
  final VoidCallback onPurchase;

  const PetsGridCard({
    super.key,
    required this.pet,
    required this.isOwned,
    required this.isActive,
    required this.isBuying,
    required this.onSelect,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final price = pet['price'] as int? ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: c.card, // Cambia automáticamente entre blanco y gris oscuro
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isActive ? AppTheme.primary : Colors.transparent, width: 2),
        boxShadow: [
          BoxShadow(
            color: isActive ? AppTheme.primary.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12, offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(10)),
                child: const Text('Activa', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
              )
            else
              const SizedBox(height: 20),
            const SizedBox(height: 8),
            Expanded(
              child: pet['base_url'] != null
                  ? FutureBuilder<Uint8List?>(
                // CORRECCIÓN: Apuntamos al key correcto '_base' que definimos en tu prefetch
                future: CacheService.getImage(pet['base_url'] as String, '${pet['slug']}_base'),
                builder: (_, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) return Image.memory(snapshot.data!, fit: BoxFit.contain);
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight, strokeWidth: 2));
                },
              )
                  : Icon(Icons.pets, size: 60, color: c.textMuted),
            ),
            const SizedBox(height: 10),
            Text(pet['name'] as String? ?? '', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c.textPrimary), textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(pet['description'] ?? '', style: TextStyle(fontSize: 11, color: c.textMuted), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity, height: 36,
              child: isBuying
                  ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryLight)))
                  : isOwned
                  ? ElevatedButton(
                onPressed: isActive ? null : onSelect,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isActive ? c.border : AppTheme.primary,
                  foregroundColor: isActive ? c.textMuted : Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(isActive ? 'Seleccionada' : 'Seleccionar', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              )
                  : ElevatedButton(
                onPressed: onPurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(price == 0 ? 'Gratis' : '$price 🪙', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}