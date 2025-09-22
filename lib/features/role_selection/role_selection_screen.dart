// lib/features/role_selection/role_selection_screen.dart

import 'package:event_management_app/features/coordinator/auth/coordinator_login_screen.dart';
import 'package:flutter/material.dart';
// Note: We will create these login screens in the next steps.
// import 'package:ideathon_monitor/features/coordinator/auth/coordinator_login_screen.dart';
// import 'package:ideathon_monitor/features/participant/auth/participant_login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Ideathon 2025',
              style: textTheme.headlineMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Welcome',
              style: textTheme.headlineSmall?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 60),
            _RoleButton(
              icon: Icons.people,
              label: 'I am a Participant',
              onTap: () {
                // TODO: Navigate to Participant Login
                // Navigator.push(context, MaterialPageRoute(builder: (context) => const ParticipantLoginScreen()));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Participant login coming next!'),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            _RoleButton(
              icon: Icons.support_agent,
              label: 'I am a Coordinator',
              onTap: () {
                // UPDATE THIS PART
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CoordinatorLoginScreen(),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Coordinator login coming next!'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleButton extends StatelessWidget {
  const _RoleButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}
