import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_pet_card.dart';
import '../widgets/dashboard_water_buttons.dart';
import '../widgets/dashboard_stats_row.dart';
import '../widgets/dashboard_bottom_nav.dart';
import 'stats_screen.dart';
import 'pets_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';
import '../services/cache_service.dart';
import '../services/connectivity_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _totalMl = 0;
  int _goalMl = 2000;
  int _streak = 0;
  bool _loading = false;
  int _selectedIndex = 0;

  // Guardamos el mapa completo de estados de la mascota activa
  Map<String, dynamic>? _activePetData;

  @override
  void initState() {
    super.initState();
    _loadData();
    _setupSyncListener();
  }

  void _setupSyncListener() {
    ConnectivityService.onConnectivityChanged().listen((isConnected) {
      if (isConnected) {
        debugPrint('Conexión restaurada, sincronizando...');
        _syncPendingData();
      }
    });
  }

  Future<void> _syncPendingData() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    await CacheService.syncPendingLogs((log) async {
      await Supabase.instance.client
          .schema('waterapp')
          .rpc('log_water', params: {
        'p_user_id': uid,
        'p_amount_ml': log['amount_ml'],
        'p_drink_type': log['drink_type'],
      });
    });

    await _loadData();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Datos sincronizados ✓'),
          backgroundColor: Color(0xFF2D7A4F),
        ),
      );
    }
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final db = Supabase.instance.client.schema('waterapp');

      final goalRes = await Supabase.instance.client
          .schema('waterapp')
          .rpc('get_daily_goal', params: {'p_user_id': uid});

      final nowUtc = DateTime.now().toUtc();

      // Ampliamos el rango para traer logs desde el inicio de AYER hasta el fin de HOY
      final startOfYesterdayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day)
          .subtract(const Duration(days: 1))
          .toIso8601String();
      final endOfDayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, 23, 59, 59)
          .toIso8601String();

      final logsRes = await db
          .from('logs')
          .select('amount_ml, logged_at')
          .eq('user_id', uid)
          .gte('logged_at', startOfYesterdayUtc)
          .lte('logged_at', endOfDayUtc);

      final streakRes = await db
          .from('streaks')
          .select('current_streak')
          .eq('user_id', uid)
          .maybeSingle();

      final profileRes = await db
          .from('profiles')
          .select('active_pet_id')
          .eq('user_id', uid)
          .maybeSingle();

      final goal = goalRes ?? 2000;

      // Separar el agua consumida ayer y hoy usando fechas locales del dispositivo
      final nowLocal = DateTime.now();
      final todayKey = '${nowLocal.year}-${nowLocal.month.toString().padLeft(2,'0')}-${nowLocal.day.toString().padLeft(2,'0')}';

      final yestLocal = nowLocal.subtract(const Duration(days: 1));
      final yesterdayKey = '${yestLocal.year}-${yestLocal.month.toString().padLeft(2,'0')}-${yestLocal.day.toString().padLeft(2,'0')}';

      int totalToday = 0;
      int totalYesterday = 0;

      for (final log in logsRes as List) {
        final dt = DateTime.parse(log['logged_at']).toLocal();
        final key = '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')}';

        if (key == todayKey) {
          totalToday += log['amount_ml'] as int;
        } else if (key == yesterdayKey) {
          totalYesterday += log['amount_ml'] as int;
        }
      }

      // Lógica de validación de racha instantánea
      int currentStreak = streakRes?['current_streak'] ?? 0;

      if (totalYesterday < goal) {
        currentStreak = (totalToday >= goal) ? 1 : 0;
      }

      // CORRECCIÓN AQUÍ: Declaramos petData correctamente asignando la respuesta de la DB
      Map<String, dynamic>? petData;
      if (profileRes != null && profileRes['active_pet_id'] != null) {
        petData = await db
            .from('pets')
            .select('id, slug, base_url, hydrated_url, dehydrated_url')
            .eq('id', profileRes['active_pet_id'])
            .maybeSingle();
      }

      setState(() {
        _goalMl = goal;
        _totalMl = totalToday;
        _streak = currentStreak;
        _activePetData = petData; // Ahora sí existe perfectamente
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando datos: $e');
      setState(() => _loading = false);
    }
  }

  // Nueva función que calcula en tiempo real qué URL usar según el progreso actual
  String? _getCurrentPetImageUrl() {
    if (_activePetData == null) return null;
    final pct = _goalMl > 0 ? (_totalMl / _goalMl) : 0.0;

    if (pct >= 0.8) return _activePetData!['hydrated_url'] as String?;
    if (pct >= 0.4) return _activePetData!['base_url'] as String?;
    return _activePetData!['dehydrated_url'] as String?;
  }

  String? _getCurrentPetCacheKey() {
    if (_activePetData == null) return null;
    final slug = _activePetData!['slug'] as String? ?? _activePetData!['id'].toString();
    final pct = _goalMl > 0 ? (_totalMl / _goalMl) : 0.0;

    if (pct >= 0.8) return '${slug}_hydrated';
    if (pct >= 0.4) return '${slug}_base';
    return '${slug}_dehydrated';
  }

  Future<void> _logWater(int ml) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    // Actualización optimista e instantánea
    final wasGoalMet = _totalMl >= _goalMl;
    final willBeGoalMet = (_totalMl + ml) >= _goalMl;

    setState(() {
      _totalMl += ml;
      if (!wasGoalMet && willBeGoalMet) {
        _streak += 1;
      }
    });

    final logData = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'user_id': uid,
      'amount_ml': ml,
      'drink_type': 'water',
      'logged_at': DateTime.now().toIso8601String(),
    };

    try {
      final hasConnection = await ConnectivityService.hasConnection();

      if (hasConnection) {
        final res = await Supabase.instance.client
            .schema('waterapp')
            .rpc('log_water', params: {
          'p_user_id': uid,
          'p_amount_ml': ml,
          'p_drink_type': 'water',
        });

        _updateUIAfterLog(res);
      } else {
        await CacheService.savePendingLog(logData);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrado sin conexión. Se sincronizará cuando haya internet'),
              backgroundColor: AppTheme.primaryLight,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error registrando agua: $e');
      await CacheService.savePendingLog(logData);
    }
  }

  void _updateUIAfterLog(Map<String, dynamic> res) {
    final newTotal = res['total_today'] as int;
    final goal = res['goal'] as int;
    final dbStreak = res['current_streak'] as int?;

    setState(() {
      _totalMl = newTotal;
      _goalMl = goal;

      if (dbStreak != null) {
        _streak = dbStreak;
      }
    });
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  String _getPetStatus() {
    final pct = _goalMl > 0 ? (_totalMl / _goalMl) : 0.0;
    if (pct >= 0.8) return '¡Tu mascota está bien hidratada! 💧';
    if (pct >= 0.4) return 'Vas bien, sigue tomando agua 🙂';
    return 'Tu mascota tiene sed... ¡hidrátatе! 😟';
  }

  bool get _showMainHeader => _selectedIndex == 0;

  Widget _buildScreen() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (_selectedIndex) {
      case 0:
        return _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryLight))
            : RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                PetCard(
                  petImageUrl: _getCurrentPetImageUrl(),
                  petCacheKey: _getCurrentPetCacheKey(),
                  totalMl: _totalMl,
                  goalMl: _goalMl,
                  statusText: _getPetStatus(),
                  statusColor: _goalMl > 0
                      ? (_totalMl / _goalMl) >= 0.8
                      ? (isDark ? const Color(0xFF63E6BE) : const Color(0xFF2D7A4F))
                      : (_totalMl / _goalMl) >= 0.4
                      ? AppTheme.primaryLight
                      : const Color(0xFFDC2626)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(height: 24),
                WaterButtonsSection(onLogWater: _logWater),
                const SizedBox(height: 24),
                StatsRow(
                  goalMl: _goalMl,
                  totalMl: _totalMl,
                  streak: _streak,
                ),
              ],
            ),
          ),
        );
      case 1:
        return const StatsScreen();
      case 2:
        return const PetsScreen();
      case 3:
        return const AchievementsScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const Center(child: Text('Error'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (_showMainHeader)
              DashboardHeader(
                streak: _streak,
                onLogout: _signOut,
              ),
            Expanded(child: _buildScreen()),
            DashboardBottomNav(
              selectedIndex: _selectedIndex,
              onTabChanged: (index) {
                setState(() => _selectedIndex = index);
                if (index == 0) _loadData();
              },
            ),
          ],
        ),
      ),
    );
  }
}