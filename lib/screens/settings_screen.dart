import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../theme/app_theme.dart';
import '../widgets/settings_account_section.dart';
import '../widgets/settings_appearance_section.dart';
import '../widgets/settings_hydration_section.dart';
import '../widgets/settings_schedules_section.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String    _email         = '';
  int       _balance       = 0;
  double    _weightKg      = 70;
  String    _activityLevel = 'medium';
  TimeOfDay _wakeTime      = const TimeOfDay(hour: 7,  minute: 0);
  TimeOfDay _sleepTime     = const TimeOfDay(hour: 23, minute: 0);
  bool      _isPremium     = false;
  bool      _loading       = true;
  bool      _saving        = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    themeService.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    themeService.removeListener(() => setState(() {}));
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final db = Supabase.instance.client.schema('waterapp');
      final results = await Future.wait([
        db.from('profiles').select('weight_kg, activity_level, wake_time, sleep_time').eq('user_id', user.id).maybeSingle(),
        Supabase.instance.client.from('profiles').select('balance').eq('id', user.id).maybeSingle(),
        db.from('subscriptions').select('status').eq('user_id', user.id).eq('status', 'active').maybeSingle(),
      ]);

      final profile    = results[0] as Map<String, dynamic>?;
      final profilePub = results[1] as Map<String, dynamic>?;

      setState(() {
        _email         = user.email ?? '';
        _balance       = (profilePub?['balance'] as int?) ?? 0;
        _weightKg      = (profile?['weight_kg'] as num?)?.toDouble() ?? 70;
        _activityLevel = profile?['activity_level'] ?? 'medium';
        _loading       = false;

        if (profile != null) {
          if (profile['wake_time'] != null) {
            final p = (profile['wake_time'] as String).split(':');
            _wakeTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
          }
          if (profile['sleep_time'] != null) {
            final p = (profile['sleep_time'] as String).split(':');
            _sleepTime = TimeOfDay(hour: int.parse(p[0]), minute: int.parse(p[1]));
          }
        }
      });
    } catch (e) {
      debugPrint('Error settings: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      final wakeStr  = '${_wakeTime.hour.toString().padLeft(2,'0')}:${_wakeTime.minute.toString().padLeft(2,'0')}:00';
      final sleepStr = '${_sleepTime.hour.toString().padLeft(2,'0')}:${_sleepTime.minute.toString().padLeft(2,'0')}:00';
      await Supabase.instance.client.schema('waterapp').from('profiles').update({
        'weight_kg':      _weightKg,
        'activity_level': _activityLevel,
        'wake_time':      wakeStr,
        'sleep_time':     sleepStr,
      }).eq('user_id', uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración guardada ✓'), backgroundColor: Color(0xFF2D7A4F)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
  }

  Future<void> _pickTime(bool isWake) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isWake ? _wakeTime : _sleepTime,
    );
    if (picked != null) setState(() => isWake ? _wakeTime = picked : _sleepTime = picked);
  }

  void _showPremiumModal() {
    final c = AppColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: c.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 24),
            const Text('⭐', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('WaterApp Premium', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c.textPrimary)),
            const SizedBox(height: 8),
            Text('Desbloquea todo el potencial de la app', style: TextStyle(fontSize: 14, color: c.textMuted), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ...[
              ('Meta personalizada por peso y actividad', '🎯'),
              ('Mascotas premium con coins', '🐾'),
              ('Historial ilimitado y gráficas', '📊'),
              ('Recordatorios inteligentes', '🔔'),
              ('Modo clima — ajuste automático', '🌡️'),
              ('Exportar reporte PDF', '📄'),
              ('Sin anuncios', '🚫'),
            ].map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Text(f.$2, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 12),
                  Text(f.$1, style: TextStyle(fontSize: 14, color: c.textSecondary)),
                ],
              ),
            )),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _planCard('\$2.99', 'Mensual', c)),
                const SizedBox(width: 12),
                Expanded(child: _planCard('\$19.99', 'Anual\n44% descuento', c, highlight: true)),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Redirigiendo a la tienda A&B Studio...'), backgroundColor: Color(0xFF2D5BE3)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2D5BE3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Activar Premium', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Quizás después', style: TextStyle(color: c.textMuted)),
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
          ],
        ),
      ),
    );
  }

  Widget _planCard(String price, String label, AppColors c, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlight ? const Color(0xFF2D5BE3) : c.card2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: highlight ? const Color(0xFF2D5BE3) : c.border),
      ),
      child: Column(
        children: [
          Text(price, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: highlight ? Colors.white : c.textPrimary)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: highlight ? Colors.white70 : c.textMuted), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A90D9)))
            : SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajustes', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: c.textPrimary)),
              const SizedBox(height: 20),

              // ── SECCIÓN CUENTA ──
              SettingsAccountSection(email: _email, balance: _balance, isPremium: _isPremium),
              const SizedBox(height: 12),

              // ── SECCIÓN APARIENCIA ──
              const SettingsAppearanceSection(),
              const SizedBox(height: 20),

              // ── SECCIÓN PERFIL DE HIDRATACIÓN ──
              SettingsHydrationSection(
                weightKg: _weightKg,
                activityLevel: _activityLevel,
                onWeightChanged: (v) => setState(() => _weightKg = v),
                onActivityChanged: (v) => setState(() => _activityLevel = v),
              ),
              const SizedBox(height: 20),

              // ── SECCIÓN HORARIOS ──
              SettingsSchedulesSection(
                wakeTime: _wakeTime,
                sleepTime: _sleepTime,
                onWakeTimeTap: () => _pickTime(true),
                onSleepTimeTap: () => _pickTime(false),
              ),
              const SizedBox(height: 20),

              // Botón Guardar cambios
              SizedBox(
                width: double.infinity, height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5BE3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Guardar cambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 12),

              // Botón Cerrar sesión
              SizedBox(
                width: double.infinity, height: 52,
                child: OutlinedButton(
                  onPressed: _signOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cerrar sesión', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 30),
              Center(
                child: Text('WaterApp — A&B Studio © 2026', style: TextStyle(fontSize: 12, color: c.textMuted)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}