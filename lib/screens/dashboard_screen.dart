import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart'; // Importante para acceder a AppColors y AppTheme
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
  String? _petImageUrl;
  int _selectedIndex = 0;

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
      final startOfDayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day)
          .toIso8601String();
      final endOfDayUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, 23, 59, 59)
          .toIso8601String();

      final logsRes = await db
          .from('logs')
          .select('amount_ml')
          .eq('user_id', uid)
          .gte('logged_at', startOfDayUtc)
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

      final total = (logsRes as List)
          .fold<int>(0, (sum, l) => sum + (l['amount_ml'] as int));
      final goal = goalRes ?? 2000;
      final pct = goal > 0 ? total / goal : 0.0;

      String? petUrl;
      if (profileRes != null && profileRes['active_pet_id'] != null) {
        final petRes = await db
            .from('pets')
            .select('base_url, hydrated_url, dehydrated_url')
            .eq('id', profileRes['active_pet_id'])
            .maybeSingle();

        if (petRes != null) {
          petUrl = pct >= 0.8
              ? petRes['hydrated_url']
              : pct >= 0.4
              ? petRes['base_url']
              : petRes['dehydrated_url'];
        }
      }

      setState(() {
        _goalMl = goal;
        _totalMl = total;
        _streak = streakRes?['current_streak'] ?? 0;
        _petImageUrl = petUrl;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Error cargando datos: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _logWater(int ml) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

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

        setState(() {
          _totalMl += ml;
          _goalMl = _goalMl > 0 ? _goalMl : 2000;
        });

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

    if (res['goal_reached'] == true) {
      setState(() => _streak = (res['current_streak'] ?? _streak) as int);
    }

    setState(() {
      _totalMl = newTotal;
      _goalMl = goal;
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
                  petImageUrl: _petImageUrl,
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
    final c = AppColors.of(context); // Captura los colores adaptativos de tu ThemeExtension
    return Scaffold(
      backgroundColor: c.bg, // Cambia automáticamente de color entre modos
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