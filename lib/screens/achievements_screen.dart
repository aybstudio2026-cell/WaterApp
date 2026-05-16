import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/achievements_header.dart';
import '../widgets/achievements_list_card.dart';

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
  { 'key': 'pet_owner',      'title': 'Dueño de mascota',   'desc': 'Desbloquea una mascota premium',            'icon': '🐾', 'req': 1 },
  { 'key': 'early_bird',     'title': 'Madrugador',         'desc': 'Registra agua antes de las 8am por 7 días', 'icon': '🌅', 'req': 7 },
  { 'key': 'hydration_hero', 'title': 'Héroe hidratado',    'desc': 'Alcanza el 150% de tu meta en un día',      'icon': '🦸', 'req': 1 },
];

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  List<String> _unlocked = [];
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
      final res = await Supabase.instance.client
          .schema('waterapp')
          .from('achievements')
          .select('achievement_key')
          .eq('user_id', uid);

      setState(() {
        _unlocked = (res as List).map((r) => r['achievement_key'] as String).toList();
        _loading  = false;
      });
    } catch (e) {
      debugPrint('Error logros: $e');
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.bg, // Reacciona dinámicamente al fondo oscuro
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AchievementsHeader(
              unlockedCount: _unlocked.length,
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
                  itemBuilder: (_, i) => AchievementsListCard(
                    achievement: kAchievements[i],
                    isUnlocked: _unlocked.contains(kAchievements[i]['key']),
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