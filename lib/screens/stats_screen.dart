import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  List<Map<String, dynamic>> _weekData = [];
  int _goalMl   = 2000;
  int _avgMl    = 0;
  int _bestStreak = 0;
  int _daysmet  = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final db = Supabase.instance.client.schema('waterapp');

      // Meta — con schema correcto
      final goalRes = await Supabase.instance.client
          .schema('waterapp')
          .rpc('get_daily_goal', params: {'p_user_id': uid});

      // Logs últimos 7 días
      final now   = DateTime.now();
      final since = DateTime.utc(now.year, now.month, now.day)
          .subtract(const Duration(days: 6))
          .toIso8601String();

      final logs = await db
          .from('logs')
          .select('amount_ml, logged_at')
          .eq('user_id', uid)
          .gte('logged_at', since)
          .order('logged_at');

      // Racha
      final streakRes = await db
          .from('streaks')
          .select('current_streak, best_streak')
          .eq('user_id', uid)
          .maybeSingle();

      // Agrupar por día
      final Map<String, int> byDay = {};
      for (var i = 0; i < 7; i++) {
        final d = DateTime.now().subtract(Duration(days: 6 - i));
        final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        byDay[key] = 0;
      }

      for (final log in logs as List) {
        // Convertir UTC a local para agrupar correctamente
        final dt  = DateTime.parse(log['logged_at']).toLocal();
        final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';
        if (byDay.containsKey(key)) {
          byDay[key] = byDay[key]! + (log['amount_ml'] as int);
        }
      }

      final weekData = byDay.entries.map((e) {
        final dt = DateTime.parse(e.key);
        return {
          'date': e.key,
          'day':  _dayLabel(dt.weekday),
          'ml':   e.value,
        };
      }).toList();

      final goal  = (goalRes as int?) ?? 2000;
      final total = weekData.fold<int>(0, (s, d) => s + (d['ml'] as int));
      final met   = weekData.where((d) => (d['ml'] as int) >= goal).length;

      setState(() {
        _weekData   = weekData;
        _goalMl     = goal;
        _avgMl      = total ~/ 7;
        _daysmet    = met;
        _bestStreak = streakRes?['best_streak'] ?? 0;
        _loading    = false;
      });
    } catch (e) {
      debugPrint('Error stats: $e');
      setState(() => _loading = false);
    }
  }

  String _dayLabel(int weekday) {
    const days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    return days[weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A90D9)))
            : RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Estadísticas',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2E6E))),
                const SizedBox(height: 4),
                const Text('Últimos 7 días',
                    style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                const SizedBox(height: 20),

                _buildSummaryCards(),
                const SizedBox(height: 24),
                _buildWeekChart(),
                const SizedBox(height: 24),
                _buildDayList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _summaryCard('Promedio', '$_avgMl ml', Icons.water_drop_outlined, const Color(0xFFD6E4FF)),
        const SizedBox(width: 12),
        _summaryCard('Meta cumplida', '$_daysmet / 7 días', Icons.check_circle_outline, const Color(0xFFD6F5E3)),
        const SizedBox(width: 12),
        _summaryCard('Mejor racha', '$_bestStreak días', Icons.local_fire_department_outlined, const Color(0xFFFFEDD5)),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: const Color(0xFF1A2E6E)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF1A2E6E))),
            Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekChart() {
    final maxMl = _weekData.fold<int>(
      _goalMl,
          (m, d) => (d['ml'] as int) > m ? (d['ml'] as int) : m,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Consumo diario',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A2E6E))),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _weekData.map((d) {
                final ml   = d['ml'] as int;
                final pct  = maxMl > 0 ? ml / maxMl : 0.0;
                final metGoal = ml >= _goalMl;
                final isToday = d['day'] == _dayLabel(DateTime.now().weekday);

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (ml > 0)
                          Text(
                            ml >= 1000 ? '${(ml/1000).toStringAsFixed(1)}L' : '${ml}ml',
                            style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
                          ),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: pct > 0 ? 120 * pct : 4,
                          decoration: BoxDecoration(
                            color: metGoal
                                ? const Color(0xFF2D7A4F)
                                : isToday
                                ? const Color(0xFF4A90D9)
                                : const Color(0xFFD1E4F5),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(d['day'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: isToday ? const Color(0xFF2D5BE3) : const Color(0xFF9CA3AF),
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                            )),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Leyenda
          Row(
            children: [
              _legend(const Color(0xFF2D7A4F), 'Meta cumplida'),
              const SizedBox(width: 16),
              _legend(const Color(0xFF4A90D9), 'Hoy'),
              const SizedBox(width: 16),
              _legend(const Color(0xFFD1E4F5), 'Sin meta'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legend(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
      ],
    );
  }

  Widget _buildDayList() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Detalle por día',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1A2E6E))),
          const SizedBox(height: 16),
          ..._weekData.reversed.map((d) {
            final ml      = d['ml'] as int;
            final metGoal = ml >= _goalMl;
            final pct     = _goalMl > 0 ? (ml / _goalMl).clamp(0.0, 1.0) : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                children: [
                  SizedBox(
                    width: 40,
                    child: Text(d['day'] as String,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                            color: Color(0xFF374151))),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 10,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: AlwaysStoppedAnimation(
                            metGoal ? const Color(0xFF2D7A4F) : const Color(0xFF4A90D9)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 32,
                    child: Text(metGoal ? '✅' : ml > 0 ? '🔄' : '—',
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}