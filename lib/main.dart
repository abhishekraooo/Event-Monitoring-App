// lib/main.dart

import 'package:event_management_app/features/coordinator/auth/coordinator_auth_gate.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:event_management_app/core/theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    final supabaseUrl = const String.fromEnvironment(
      'FLUTTER_PUBLIC_SUPABASE_URL',
    );
    final supabaseAnonKey = const String.fromEnvironment(
      'FLUTTER_PUBLIC_SUPABASE_ANON_KEY',
    );
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  } else {
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }
  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ideathon 2025 Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const CoordinatorAuthGate(),
    );
  }
}
