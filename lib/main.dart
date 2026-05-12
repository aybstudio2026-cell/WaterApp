import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'services/cache_service.dart';
import 'services/theme_service.dart';
import 'theme/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';

final themeService = ThemeService();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await CacheService.init();
  await Supabase.initialize(
    url: 'https://atlkkuwcrcrxrmkggcro.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0bGtrdXdjcmNyeHJta2dnY3JvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwMjQxOTYsImV4cCI6MjA5MTYwMDE5Nn0.RGoUlaTQnFZQk2919MOA--XZaMQIp_wvKfL1R6O05XQ',
  );
  runApp(const ProviderScope(child: WaterApp()));
}

final supabase = Supabase.instance.client;

class WaterApp extends StatefulWidget {
  const WaterApp({super.key});

  @override
  State<WaterApp> createState() => _WaterAppState();
}

class _WaterAppState extends State<WaterApp> {
  @override
  void initState() {
    super.initState();
    themeService.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaterApp',
      debugShowCheckedModeBanner: false,
      theme:      AppTheme.light(),
      darkTheme:  AppTheme.dark(),
      themeMode:  themeService.themeMode,
      home: const _SplashGate(),
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        '/login':     (_) => const LoginScreen(),
      },
    );
  }
}

class _SplashGate extends StatefulWidget {
  const _SplashGate();
  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    await Future.delayed(const Duration(milliseconds: 800));
    final session = Supabase.instance.client.auth.currentSession;
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        session != null ? '/dashboard' : '/login',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.water_drop, size: 72, color: Color(0xFF4A90D9)),
            const SizedBox(height: 16),
            Text('WaterApp',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: c.textPrimary)),
            const SizedBox(height: 8),
            Text('A&B Studio',
                style: TextStyle(fontSize: 14, color: c.textMuted)),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Color(0xFF4A90D9), strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}