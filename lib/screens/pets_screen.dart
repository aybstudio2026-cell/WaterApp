import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';
import '../services/cache_service.dart';

class PetsScreen extends StatefulWidget {
  const PetsScreen({super.key});

  @override
  State<PetsScreen> createState() => _PetsScreenState();
}

class _PetsScreenState extends State<PetsScreen> {
  List<Map<String, dynamic>> _allPets    = [];
  List<String>               _ownedIds   = [];
  String?                    _activePetId;
  int                        _balance    = 0;
  bool                       _loading    = true;
  String?                    _buying;

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final db = Supabase.instance.client.schema('waterapp');

      // Cargar todo en paralelo para mayor velocidad
      final results = await Future.wait([
        db.from('pets').select().order('price'),
        db.from('user_pets').select('pet_id').eq('user_id', uid),
        db.from('profiles').select('active_pet_id').eq('user_id', uid).maybeSingle(),
        Supabase.instance.client
            .from('profiles')
            .select('balance')
            .eq('id', uid)
            .maybeSingle(),
      ]);

      final allPets   = results[0] as List;
      final userPets  = results[1] as List;
      final profile   = results[2] as Map<String, dynamic>?;
      final pubProfile = results[3] as Map<String, dynamic>?;

      // Guardar mascotas en caché
      await CacheService.savePets(
        List<Map<String, dynamic>>.from(allPets),
      );

      // Pre-descargar imágenes en background sin bloquear la UI
      _prefetchImages(allPets);

      setState(() {
        _allPets     = List<Map<String, dynamic>>.from(allPets);
        _ownedIds    = userPets.map((p) => p['pet_id'] as String).toList();
        _activePetId = profile?['active_pet_id'] as String?;
        _balance     = (pubProfile?['balance'] as int?) ?? 0;
        _loading     = false;
      });

    } catch (e) {
      debugPrint('Error cargando mascotas: $e');

      // Fallback al caché si no hay conexión
      final cachedPets = CacheService.getPets();
      if (cachedPets.isNotEmpty) {
        setState(() {
          _allPets = cachedPets;
          _loading = false;
        });
        return;
      }
      setState(() => _loading = false);
    }
  }

// Descarga imágenes en background sin bloquear la UI
  void _prefetchImages(List allPets) {
    for (final pet in allPets) {
      final petData = pet as Map<String, dynamic>;
      final slug = petData['slug'] as String? ?? '';
      if (petData['base_url'] != null) {
        CacheService.downloadAndCacheImage(
          petData['base_url'] as String,
          '${slug}_normal',
        );
      }
      if (petData['hydrated_url'] != null) {
        CacheService.downloadAndCacheImage(
          petData['hydrated_url'] as String,
          '${slug}_hydrated',
        );
      }
      if (petData['dehydrated_url'] != null) {
        CacheService.downloadAndCacheImage(
          petData['dehydrated_url'] as String,
          '${slug}_dehydrated',
        );
      }
    }
  }

  Future<void> _purchasePet(String petId) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    setState(() => _buying = petId);
    try {
      final res = await Supabase.instance.client
          .schema('waterapp')
          .rpc('purchase_pet', params: {
        'p_user_id': uid,
        'p_pet_id':  petId,
      });

      debugPrint('purchase_pet response: $res');

      await _loadPets();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Mascota desbloqueada! 🎉'),
            backgroundColor: Color(0xFF2D7A4F),
          ),
        );
      }
    } catch (e) {
      debugPrint('purchase_pet error: $e'); // ← Mira el log aquí

      if (mounted) {
        final msg = e.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $msg'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _buying = null);
    }
  }

  Future<void> _selectPet(String petId) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      await Supabase.instance.client
          .schema('waterapp')
          .from('profiles')
          .update({'active_pet_id': petId})
          .eq('user_id', uid);

      setState(() => _activePetId = petId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Mascota seleccionada! 🐾'),
            backgroundColor: Color(0xFF4A90D9),
          ),
        );

        // Vuelve al dashboard automáticamente
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            Navigator.of(context).pushNamed('/dashboard');
          }
        });
      }
    } catch (e) {
      debugPrint('Error seleccionando mascota: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mascotas',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2E6E))),
                      Text('Selecciona tu compañero',
                          style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                    ],
                  ),
                  // Balance
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6F5E3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('⚡', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text('$_balance coins',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                color: Color(0xFF2D7A4F))),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A90D9)))
                  : RefreshIndicator(
                onRefresh: _loadPets,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: _allPets.length,
                  itemBuilder: (_, i) => _buildPetCard(_allPets[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    final id      = pet['id'] as String;
    final owned   = _ownedIds.contains(id);
    final active  = _activePetId == id;
    final isFree  = pet['is_free'] as bool;
    final price   = pet['price'] as int;
    final buying  = _buying == id;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active ? const Color(0xFF2D5BE3) : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? const Color(0xFF2D5BE3).withOpacity(0.15)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Badge activo
            if (active)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2D5BE3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Activa',
                    style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600)),
              )
            else
              const SizedBox(height: 20),

            const SizedBox(height: 8),

            // Imagen de la mascota
            Expanded(
              child: pet['base_url'] != null
                  ? FutureBuilder<Uint8List?>(
                future: CacheService.getImage(
                  pet['base_url'] as String,
                  '${pet['slug']}_normal',
                ),
                builder: (_, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.contain,
                    );
                  }
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF4A90D9),
                    ),
                  );
                },
              )
                  : const Icon(Icons.pets, size: 60, color: Color(0xFF4A90D9)),
            ),

            const SizedBox(height: 10),

            // Nombre
            Text(pet['name'] as String,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A2E6E)),
                textAlign: TextAlign.center),

            const SizedBox(height: 4),

            // Descripción corta
            Text(
              pet['description'] ?? '',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 12),

            // Botón
            SizedBox(
              width: double.infinity,
              height: 36,
              child: buying
                  ? const Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4A90D9))))
                  : owned
                  ? ElevatedButton(
                onPressed: active ? null : () => _selectPet(id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: active ? const Color(0xFFE5E7EB) : const Color(0xFF2D5BE3),
                  foregroundColor: active ? const Color(0xFF9CA3AF) : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(active ? 'Seleccionada' : 'Seleccionar',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              )
                  : ElevatedButton(
                onPressed: () => _purchasePet(id),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFree ? const Color(0xFF2D7A4F) : const Color(0xFF1A2E6E),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  isFree ? 'Gratis' : '$price coins',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}