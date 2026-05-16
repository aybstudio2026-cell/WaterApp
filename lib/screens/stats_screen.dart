import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/stats_summary_cards.dart';
import '../widgets/stats_week_chart.dart';
import '../widgets/stats_day_list.dart';

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

      final goalRes = await Supabase.instance.client
          .schema('waterapp')
          .rpc('get_daily_goal', params: {'p_user_id': uid});

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

      final streakRes = await db
          .from('streaks')
          .select('current_streak, best_streak')
          .eq('user_id', uid)
          .maybeSingle();

      final Map<String, int> byDay = {};
      for (var i = 0; i < 7; i++) {
        final d = DateTime.now().subtract(Duration(days: 6 - i));
        final key = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
        byDay[key] = 0;
      }

      for (final log in logs as List) {
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
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg, // Cambia de fondo automáticamente
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight))
            : RefreshIndicator(
          onRefresh: _loadStats,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Estadísticas', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c.textPrimary)),
                const SizedBox(height: 4),
                Text('Últimos 7 días', style: TextStyle(fontSize: 14, color: c.textMuted)),
                const SizedBox(height: 20),

                StatsSummaryCards(avgMl: _avgMl, daysMet: _daysmet, bestStreak: _bestStreak),
                const SizedBox(height: 24),
                StatsWeekChart(weekData: _weekData, goalMl: _goalMl, currentDayLabel: _dayLabel(DateTime.now().weekday)),
                const SizedBox(height: 24),
                StatsDayList(weekData: _weekData, goalMl: _goalMl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}