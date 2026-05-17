import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/achievements_header.dart';
import '../widgets/achievements_list_card.dart';

// Lista actualizada (removido el dueño de mascota)
const List<Map<String, dynamic>> kAchievements = [
  { 'key': 'first_log',      'title': 'Primera gota',       'desc': 'Registra tu primer vaso de agua',          'icon': '💧', 'req': 1 },
  { 'key': 'week_streak',    'title': 'Racha de 7 días',    'desc': 'Cumple tu meta 7 días seguidos',            'icon': '🔥', 'req': 7 },
  { 'key': 'logs_100',       'title': '100 registros',      'desc': 'Registra agua 100 veces',                   'icon': '📝', 'req': 100 },
  { 'key': 'goal_30',        'title': 'Mes completo',        'desc': 'Cumple tu meta 30 días seguidos',           'icon': '🌊', 'req': 30 },
  { 'key': 'streak_30',      'title': 'Racha de 30 días',   'desc': 'Mantén una racha de 30 días',               'icon': '⚡', 'req': 30 },
  { 'key': 'goal_100',       'title': 'Centenario',         'desc': 'Cumple tu meta 100 días en total',          'icon': '🏆', 'req': 100 },
  { 'key': 'total_10l',      'title': '10 litros totales',  'desc': 'Consume 10 litros de agua en total',        'icon': '🪣', 'req': 10000 },
  { 'key': 'total_100l',     'title': '100 litros',         'desc': 'Consume 100 litros de agua en total',       'icon': '🌊', 'req': 100000 },
  { 'key': 'streak_60',      'title': '60 días sin fallar', 'desc': 'Mantén una racha de 60 días',               'icon': '🛡️', 'req': 60 },
  { 'key': 'early_bird',     'title': 'Madrugador',         'desc': 'Registra agua antes de las 8am por 7 días', 'icon': '🌅', 'req': 7 },
  { 'key': 'hydration_hero', 'title': 'Héroe hidratado',    'desc': 'Alcanza el 150% de tu meta en un día',      'icon': '🦸', 'req': 1 },
];

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  // Mapeamos los logros usando la llave como identificador para almacenar sus datos de DB
  Map<String, Map<String, dynamic>> _unlockedData = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final db = Supabase.instance.client.schema('waterapp');

      // Traemos id, key y el estado de la recompensa cobrada
      final res = await db.from('achievements').select('id, achievement_key, reward_claimed').eq('user_id', uid);

      final Map<String, Map<String, dynamic>> tempMap = {};
      for (final row in res as List) {
        tempMap[row['achievement_key']] = {
          'id': row['id'],
          'claimed': row['reward_claimed'] ?? false,
        };
      }

      setState(() {
        _unlockedData = tempMap;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error logros: $e');
      setState(() => _loading = false);
    }
  }

  // Función para invocar el RPC cuando el usuario pulse el botón
  Future<void> _claimReward(String achievementId, String key) async {
    try {
      // Ejecutamos la función de Supabase
      final int newBalance = await Supabase.instance.client
          .schema('waterapp')
          .rpc('claim_achievement_reward', params: {'p_achievement_id': achievementId});

      // Actualizamos la UI localmente al instante
      setState(() {
        if (_unlockedData.containsKey(key)) {
          _unlockedData[key]!['claimed'] = true;
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('¡Reclamaste +10 🪙! Nuevo saldo: $newBalance'),
            backgroundColor: const Color(0xFF2D7A4F),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error al reclamar recompensa: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AchievementsHeader(
              unlockedCount: _unlockedData.length,
              totalCount: kAchievements.length,
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight))
                  : RefreshIndicator(
                onRefresh: _loadAchievements,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: kAchievements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final itemKey = kAchievements[i]['key'];
                    final isUnlocked = _unlockedData.containsKey(itemKey);
                    final isClaimed = isUnlocked ? (_unlockedData[itemKey]!['claimed'] ?? false) : false;
                    final dbId = isUnlocked ? (_unlockedData[itemKey]!['id'] as String) : '';

                    return AchievementsListCard(
                      achievement: kAchievements[i],
                      isUnlocked: isUnlocked,
                      isClaimed: isClaimed, // Pásale si ya fue cobrado
                      onClaimTap: (isUnlocked && !isClaimed)
                          ? () => _claimReward(dbId, itemKey)
                          : null, // Pásale la función de reclamo
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}