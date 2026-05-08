import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import '../services/cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar caché
  await CacheService.init();

  await Supabase.initialize(
    url: 'https://atlkkuwcrcrxrmkggcro.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF0bGtrdXdjcmNyeHJta2dnY3JvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYwMjQxOTYsImV4cCI6MjA5MTYwMDE5Nn0.RGoUlaTQnFZQk2919MOA--XZaMQIp_wvKfL1R6O05XQ',
  );

  runApp(const ProviderScope(child: WaterApp()));
}

final supabase = Supabase.instance.client;

class WaterApp extends StatelessWidget {
  const WaterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WaterApp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF4A90D9),
        useMaterial3: true,
      ),
      home: const _SplashGate(),
      routes: {
        '/dashboard': (_) => const DashboardScreen(),
        '/login':     (_) => const LoginScreen(),
      },
    );
  }
}

// Decide a dónde ir según si hay sesión activa
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
      if (session != null) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Pantalla de splash mientras decide
    return const Scaffold(
      backgroundColor: Color(0xFFF4F6FA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.water_drop, size: 72, color: Color(0xFF4A90D9)),
            SizedBox(height: 16),
            Text('WaterApp',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A2E6E),
                )),
            SizedBox(height: 8),
            Text('A&B Studio',
                style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF))),
            SizedBox(height: 40),
            CircularProgressIndicator(
              color: Color(0xFF4A90D9),
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}