import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../theme/app_theme.dart';

class CachedPetImage extends StatelessWidget {
  final String? url;
  final String? cacheKey;
  final double height;

  const CachedPetImage({
    super.key,
    required this.url,
    required this.cacheKey,
    this.height = 140,
  });

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty || cacheKey == null || cacheKey!.isEmpty) {
      return Icon(Icons.pets, size: height * 0.6, color: AppTheme.primaryLight);
    }

    return FutureBuilder<Uint8List?>(
      future: CacheService.getImage(url!, cacheKey!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: height,
            child: const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryLight, strokeWidth: 2),
            ),
          );
        }

        if (snapshot.hasData && snapshot.data != null) {
          return Image.memory(
            snapshot.data!,
            height: height,
            fit: BoxFit.contain,
          );
        }

        return Icon(Icons.pets, size: height * 0.6, color: AppTheme.primaryLight);
      },
    );
  }
}