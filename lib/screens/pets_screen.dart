import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../services/cache_service.dart';
import '../widgets/pets_header.dart';
import '../widgets/pets_grid_card.dart';

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
      final results = await Future.wait([
        db.from('pets').select().order('price'),
        db.from('user_pets').select('pet_id').eq('user_id', uid),
        db.from('profiles').select('active_pet_id').eq('user_id', uid).maybeSingle(),
        Supabase.instance.client.from('profiles').select('balance').eq('id', uid).maybeSingle(),
      ]);

      final allPets = results[0] as List;
      setState(() {
        _allPets     = List<Map<String, dynamic>>.from(allPets);
        _ownedIds    = (results[1] as List).map((p) => p['pet_id'] as String).toList();
        _activePetId = (results[2] as Map<String, dynamic>?)?['active_pet_id'] as String?;
        _balance     = ((results[3] as Map<String, dynamic>?)?['balance'] as int?) ?? 0;
        _loading     = false;
      });
      await CacheService.savePets(List<Map<String, dynamic>>.from(allPets));
      _prefetchImages(allPets);
    } catch (e) {
      final cachedPets = CacheService.getPets();
      if (cachedPets.isNotEmpty) {
        setState(() { _allPets = cachedPets; _loading = false; });
        return;
      }
      setState(() => _loading = false);
    }
  }

  void _prefetchImages(List allPets) {
    for (final pet in allPets) {
      final p = pet as Map<String, dynamic>;
      final slug = p['slug'] ?? '';
      if (p['base_url'] != null) CacheService.downloadAndCacheImage(p['base_url'], '${slug}_normal');
      if (p['hydrated_url'] != null) CacheService.downloadAndCacheImage(p['hydrated_url'], '${slug}_hydrated');
      if (p['dehydrated_url'] != null) CacheService.downloadAndCacheImage(p['dehydrated_url'], '${slug}_dehydrated');
    }
  }

  Future<void> _purchasePet(String petId) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _buying = petId);
    try {
      await Supabase.instance.client.schema('waterapp').rpc('purchase_pet', params: {'p_user_id': uid, 'p_pet_id': petId});
      await _loadPets();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Mascota desbloqueada! 🎉'), backgroundColor: Color(0xFF2D7A4F)));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent));
    } finally {
      setState(() => _buying = null);
    }
  }

  Future<void> _selectPet(String petId) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      await Supabase.instance.client.schema('waterapp').from('profiles').update({'active_pet_id': petId}).eq('user_id', uid);
      setState(() => _activePetId = petId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('¡Mascota seleccionada! 🐾'), backgroundColor: Color(0xFF4A90D9)));
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) Navigator.of(context).pushNamed('/dashboard');
        });
      }
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          children: [
            PetsHeader(balance: _balance),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A90D9)))
                  : RefreshIndicator(
                onRefresh: _loadPets,
                child: GridView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.75,
                  ),
                  itemCount: _allPets.length,
                  itemBuilder: (_, i) => PetsGridCard(
                    pet: _allPets[i],
                    isOwned: _ownedIds.contains(_allPets[i]['id']),
                    isActive: _activePetId == _allPets[i]['id'],
                    isBuying: _buying == _allPets[i]['id'],
                    onSelect: () => _selectPet(_allPets[i]['id']),
                    onPurchase: () => _purchasePet(_allPets[i]['id']),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}