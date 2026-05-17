import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class CacheService {
  static const String _petsBox = 'pets_cache';
  static const String _imagesBox = 'images_cache';
  static const String _logsBox = 'logs_cache';
  static const String _metadataBox = 'metadata_cache';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(_petsBox);
    await Hive.openBox(_imagesBox);
    await Hive.openBox(_logsBox);
    await Hive.openBox(_metadataBox);
  }

  // ── HELPER DE PROTECCIÓN PARA WINDOWS/ONEDRIVE ──
  /// Asegura que la caja de imágenes esté abierta antes de operar con ella
  static Future<Box> _getImagesBox() async {
    if (!Hive.isBoxOpen(_imagesBox)) {
      debugPrint('⚠️ La caja de imágenes estaba cerrada (posible bloqueo de OneDrive). Reabriendo...');
      return await Hive.openBox(_imagesBox);
    }
    return Hive.box(_imagesBox);
  }

  // ── MASCOTAS ────────────────────────────────────

  /// Guarda todas las mascotas del catálogo
  static Future<void> savePets(List<Map<String, dynamic>> pets) async {
    final box = Hive.box(_petsBox);
    for (final pet in pets) {
      await box.put(pet['id'], pet);
    }
  }

  /// Obtiene mascotas del caché
  static List<Map<String, dynamic>> getPets() {
    final box = Hive.box(_petsBox);
    return box.values
        .map((p) => Map<String, dynamic>.from(p as Map))
        .toList();
  }

  /// Limpia caché de mascotas
  static Future<void> clearPets() => Hive.box(_petsBox).clear();

  // ── IMÁGENES ────────────────────────────────────

  /// Descarga y guarda imagen en caché
  static Future<Uint8List?> downloadAndCacheImage(String url, String key) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // CORRECCIÓN: Usamos el método seguro para evitar colapsos por archivos cerrados
        final box = await _getImagesBox();
        await box.put(key, response.bodyBytes);
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('Error descargando imagen: $e');
    }
    return null;
  }

  /// Obtiene imagen del caché (sin descargar)
  static Uint8List? getCachedImage(String key) {
    if (!Hive.isBoxOpen(_imagesBox)) return null;
    final box = Hive.box(_imagesBox);
    return box.get(key) as Uint8List?;
  }

  /// Obtiene imagen: caché primero, si no existe descarga y cachea
  static Future<Uint8List?> getImage(String url, String key) async {
    var image = getCachedImage(key);
    if (image != null) return image;
    return downloadAndCacheImage(url, key);
  }

  /// Limpia caché de imágenes
  static Future<void> clearImages() async {
    final box = await _getImagesBox();
    await box.clear();
  }

  // ── LOGS OFFLINE ────────────────────────────────

  /// Guarda log localmente si no hay conexión
  static Future<void> savePendingLog(Map<String, dynamic> log) async {
    final box = Hive.box(_logsBox);
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await box.put(id, log);
  }

  /// Obtiene logs pendientes de sincronizar
  static List<Map<String, dynamic>> getPendingLogs() {
    final box = Hive.box(_logsBox);
    return box.values
        .map((l) => Map<String, dynamic>.from(l as Map))
        .toList();
  }

  /// Elimina log después de sincronizar
  static Future<void> removePendingLog(String id) async {
    final box = Hive.box(_logsBox);
    await box.delete(id);
  }

  /// Limpia todos los logs pendientes
  static Future<void> clearPendingLogs() => Hive.box(_logsBox).clear();

  // ── METADATA (última sincronización) ────────────

  /// Guarda timestamp de última sincronización
  static Future<void> setLastSync(String key, DateTime time) async {
    final box = Hive.box(_metadataBox);
    await box.put(key, time.toIso8601String());
  }

  /// Obtiene timestamp de última sincronización
  static DateTime? getLastSync(String key) {
    final box = Hive.box(_metadataBox);
    final time = box.get(key) as String?;
    return time != null ? DateTime.parse(time) : null;
  }

  /// Sincroniza logs pendientes cuando hay conexión
  static Future<void> syncPendingLogs(
      Future<void> Function(Map<String, dynamic>) uploadLog,
      ) async {
    final logs = getPendingLogs();
    for (final log in logs) {
      try {
        await uploadLog(log);
        final id = log['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
        await removePendingLog(id);
      } catch (e) {
        debugPrint('Error sincronizando log: $e');
      }
    }
  }
}