import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_pet_card.dart';
import '../widgets/dashboard_water_buttons.dart';
import '../widgets/dashboard_stats_row.dart';
import '../widgets/dashboard_bottom_nav.dart';
import 'stats_screen.dart';
import 'pets_screen.dart';
import 'achievements_screen.dart';
import 'settings_screen.dart';
import 'dart:typed_data';
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

    // Sincronizar logs pendientes
    await CacheService.syncPendingLogs((log) async {
      await Supabase.instance.client
          .schema('waterapp')
          .rpc('log_water', params: {
        'p_user_id': uid,
        'p_amount_ml': log['amount_ml'],
        'p_drink_type': log['drink_type'],
      });
    });

    // Recargar datos desde Supabase
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

      final today = DateTime.now();
      final startOfDay = DateTime.utc(today.year, today.month, today.day)
          .toIso8601String();

      final logsRes = await db
          .from('logs')
          .select('amount_ml')
          .eq('user_id', uid)
          .gte('logged_at', startOfDay);

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

    // Guardar localmente primero
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
        // Si hay conexión, enviar a Supabase
        final res = await Supabase.instance.client
            .schema('waterapp')
            .rpc('log_water', params: {
          'p_user_id': uid,
          'p_amount_ml': ml,
          'p_drink_type': 'water',
        });

        _updateUIAfterLog(res);
      } else {
        // Sin conexión, guardar localmente
        await CacheService.savePendingLog(logData);

        // Actualizar UI optimistamente
        setState(() {
          _totalMl += ml;
          _goalMl = _goalMl > 0 ? _goalMl : 2000;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registrado sin conexión. Se sincronizará cuando haya internet'),
              backgroundColor: Color(0xFF4A90D9),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error registrando agua: $e');
      // Guardamos localmente como fallback
      await CacheService.savePendingLog(logData);
    }
  }

  void _updateUIAfterLog(Map<String, dynamic> res) {
    final newTotal = res['total_today'] as int;
    final goal = res['goal'] as int;
    final pct = goal > 0 ? newTotal / goal : 0.0;

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

  Widget _buildScreen() {
    switch (_selectedIndex) {
      case 0:
        return _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A90D9)))
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
                      ? const Color(0xFF2D7A4F)
                      : (_totalMl / _goalMl) >= 0.4
                      ? const Color(0xFF4A90D9)
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            DashboardHeader(
              streak: _streak,
              onLogout: _signOut,
            ),
            Expanded(child: _buildScreen()),
            DashboardBottomNav(
              selectedIndex: _selectedIndex,
              onTabChanged: (index) => setState(() => _selectedIndex = index),
            ),
          ],
        ),
      ),
    );
  }
}