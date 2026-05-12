import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Definición de los 12 logros
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
    final unlockedCount = _unlocked.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Logros',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2E6E))),
                  const SizedBox(height: 14),
                  // Barra de progreso general
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: kAchievements.isEmpty ? 0 : unlockedCount / kAchievements.length,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE5E7EB),
                      valueColor: const AlwaysStoppedAnimation(Color(0xFF2D5BE3)),
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
                onRefresh: _loadAchievements,
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  itemCount: kAchievements.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _buildCard(kAchievements[i]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> achievement) {
    final unlocked = _unlocked.contains(achievement['key']);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: unlocked ? Colors.white : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: unlocked ? const Color(0xFF2D5BE3).withValues(alpha: 0.3) : const Color(0xFFE5E7EB),
        ),
        boxShadow: unlocked
            ? [BoxShadow(color: const Color(0xFF2D5BE3).withValues(alpha: 0.08),
            blurRadius: 12, offset: const Offset(0, 3))]
            : [],
      ),
      child: Row(
        children: [
          // Ícono
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: unlocked ? const Color(0xFFD6E4FF) : const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                unlocked ? achievement['icon'] as String : '🔒',
                style: const TextStyle(fontSize: 24),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Texto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement['title'] as String,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: unlocked ? const Color(0xFF1A2E6E) : const Color(0xFF9CA3AF),
                    )),
                const SizedBox(height: 3),
                Text(achievement['desc'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      color: unlocked ? const Color(0xFF6B7280) : const Color(0xFFD1D5DB),
                    )),
              ],
            ),
          ),

          // Badge desbloqueado
          if (unlocked)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFD6F5E3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text('✓',
                  style: TextStyle(fontSize: 12, color: Color(0xFF2D7A4F), fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }
}