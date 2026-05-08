import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String  _email        = '';
  int     _balance      = 0;
  double  _weightKg     = 70;
  String  _activityLevel = 'medium';
  TimeOfDay _wakeTime   = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleepTime  = const TimeOfDay(hour: 23, minute: 0);
  bool    _isPremium    = false;
  bool    _loading      = true;
  bool    _saving       = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      final db = Supabase.instance.client.schema('waterapp');

      // Perfil de waterapp
      final profile = await db
          .from('profiles')
          .select('weight_kg, activity_level, wake_time, sleep_time')
          .eq('user_id', user.id)
          .maybeSingle();

      // Balance del ecosistema (public)
      final profilePub = await Supabase.instance.client
          .from('profiles')
          .select('balance')
          .eq('id', user.id)
          .maybeSingle();

      // Suscripción premium
      final sub = await db
          .from('subscriptions')
          .select('status')
          .eq('user_id', user.id)
          .eq('status', 'active')
          .maybeSingle();

      setState(() {
        _email         = user.email ?? '';
        _balance       = profilePub?['balance'] ?? 0;
        _isPremium     = sub != null;
        _weightKg      = (profile?['weight_kg'] as num?)?.toDouble() ?? 70;
        _activityLevel = profile?['activity_level'] ?? 'medium';
        _loading       = false;

        if (profile != null) {
          if (profile['wake_time'] != null) {
            final parts = (profile['wake_time'] as String).split(':');
            _wakeTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
          }
          if (profile['sleep_time'] != null) {
            final parts = (profile['sleep_time'] as String).split(':');
            _sleepTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
      // Formato correcto para TIME en Supabase
      final wakeStr  = '${_wakeTime.hour.toString().padLeft(2, '0')}:${_wakeTime.minute.toString().padLeft(2, '0')}:00';
      final sleepStr = '${_sleepTime.hour.toString().padLeft(2, '0')}:${_sleepTime.minute.toString().padLeft(2, '0')}:00';

      await Supabase.instance.client
          .schema('waterapp')
          .from('profiles')
          .update({
        'weight_kg':      _weightKg,
        'activity_level': _activityLevel,
        'wake_time':      wakeStr,
        'sleep_time':     sleepStr,
      })
          .eq('user_id', uid);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada ✓'),
            backgroundColor: Color(0xFF2D7A4F),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error guardando: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
    }
  }

  Future<void> _pickTime(bool isWake) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isWake ? _wakeTime : _sleepTime,
    );
    if (picked != null) {
      setState(() => isWake ? _wakeTime = picked : _sleepTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF4A90D9)))
            : SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajustes',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1A2E6E))),
              const SizedBox(height: 20),

              // Cuenta
              _sectionTitle('Cuenta'),
              _infoCard([
                _infoRow(Icons.email_outlined, 'Correo', _email),
                _divider(),
                _infoRow(Icons.bolt_outlined, 'Balance', '$_balance coins'),
                _divider(),
                _infoRow(
                  _isPremium ? Icons.star : Icons.star_border,
                  'Plan',
                  _isPremium ? 'Premium ✓' : 'Gratuito',
                  valueColor: _isPremium ? const Color(0xFF2D7A4F) : null,
                ),
              ]),

              const SizedBox(height: 20),

              // Perfil de hidratación
              _sectionTitle('Perfil de hidratación'),
              _card(
                Column(
                  children: [
                    // Peso
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Peso',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                        Text('${_weightKg.toInt()} kg',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF4A90D9), fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Slider(
                      value: _weightKg,
                      min: 40,
                      max: 150,
                      divisions: 110,
                      activeColor: const Color(0xFF4A90D9),
                      onChanged: (v) => setState(() => _weightKg = v),
                    ),
                    const Divider(color: Color(0xFFE5E7EB)),
                    const SizedBox(height: 8),

                    // Nivel de actividad
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Nivel de actividad',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF374151))),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _activityBtn('low',    'Bajo',   '🧘'),
                        const SizedBox(width: 8),
                        _activityBtn('medium', 'Medio',  '🚶'),
                        const SizedBox(width: 8),
                        _activityBtn('high',   'Alto',   '🏃'),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Horarios
              _sectionTitle('Horarios de recordatorio'),
              _infoCard([
                _timeRow('Hora de despertar', _wakeTime, () => _pickTime(true)),
                _divider(),
                _timeRow('Hora de dormir', _sleepTime, () => _pickTime(false)),
              ]),

              const SizedBox(height: 20),

              // Guardar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2D5BE3),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _saving
                      ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                      : const Text('Guardar cambios',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 12),

              // Cerrar sesión
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _signOut,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Cerrar sesión',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),

              const SizedBox(height: 30),

              Center(
                child: Text('WaterApp — A&B Studio © 2026',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF6B7280),
          letterSpacing: 0.5,
        )),
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: child,
  );

  Widget _infoCard(List<Widget> children) => _card(Column(children: children));

  Widget _divider() => const Divider(color: Color(0xFFE5E7EB), height: 1);

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
        const Spacer(),
        Text(value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor ?? const Color(0xFF1A2E6E),
            )),
      ],
    ),
  );

  Widget _timeRow(String label, TimeOfDay time, VoidCallback onTap) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.access_time_outlined, size: 18, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF374151))),
          const Spacer(),
          Text(time.format(context),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF4A90D9))),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right, size: 16, color: Color(0xFF9CA3AF)),
        ],
      ),
    ),
  );

  Widget _activityBtn(String value, String label, String emoji) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _activityLevel = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: _activityLevel == value ? const Color(0xFF2D5BE3) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _activityLevel == value ? Colors.white : const Color(0xFF374151),
                )),
          ],
        ),
      ),
    ),
  );
}