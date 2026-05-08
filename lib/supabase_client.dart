import 'package:supabase_flutter/supabase_flutter.dart';

// Schema public (balance del ecosistema)
final publicClient = Supabase.instance.client;

// Schema waterapp — para todas las queries de la app
final waterappClient = Supabase.instance.client.schema('waterapp');