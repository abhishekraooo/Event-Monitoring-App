// lib/main.dart

import 'package:flutter/foundation.dart'; // Import to check for release mode
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:event_management_app/core/theme/app_theme.dart';
import 'package:event_management_app/features/role_selection/role_selection_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- Environment-Specific Supabase Initialization ---
  if (kReleaseMode) {
    // For Production (Vercel)
    // Vercel will pass these values during the build command.
    final supabaseUrl = const String.fromEnvironment(
      'FLUTTER_PUBLIC_SUPABASE_URL',
    );
    final supabaseAnonKey = const String.fromEnvironment(
      'FLUTTER_PUBLIC_SUPABASE_ANON_KEY',
    );
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  } else {
    // For Local Development
    // Load keys from your local .env file.
    await dotenv.load(fileName: ".env");
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
  }

  runApp(const MyApp());
}

// Global Supabase client instance
final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ideathon 2025 Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const RoleSelectionScreen(),
    );
  }
}
