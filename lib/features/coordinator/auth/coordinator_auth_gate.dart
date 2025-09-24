// lib/features/coordinator/auth/coordinator_auth_gate.dart
import 'package:event_management_app/features/coordinator/auth/coordinator_login_screen.dart';
import 'package:event_management_app/main.dart';
import 'package:event_management_app/shared/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CoordinatorAuthGate extends StatelessWidget {
  const CoordinatorAuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: supabase.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data?.session != null) {
          return const MainLayout(); // Go to dashboard if logged in
        } else {
          return const CoordinatorLoginScreen(); // Go to login if not
        }
      },
    );
  }
}
