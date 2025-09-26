// lib/features/coordinator/attendance/attendance_dashboard_screen.dart

import 'package:event_management_app/features/coordinator/attendance/attendance_check_in_screen.dart';
import 'package:event_management_app/features/coordinator/scanner/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/core/utils/snackbar_utils.dart';
// Note: We will create the check-in screen in the next step
// import 'package:event_management_app/features/coordinator/attendance/attendance_check_in_screen.dart';
// import 'package:event_management_app/features/coordinator/scanner/qr_scanner_screen.dart';

class AttendanceDashboardScreen extends StatefulWidget {
  const AttendanceDashboardScreen({super.key});

  @override
  State<AttendanceDashboardScreen> createState() =>
      _AttendanceDashboardScreenState();
}

class _AttendanceDashboardScreenState extends State<AttendanceDashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<Map<String, dynamic>>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _dbService.getParticipantStats();
  }

  Future<void> _refreshData() async {
    setState(() {
      _statsFuture = _dbService.getParticipantStats();
    });
  }

  // UPDATED: This function is now fully implemented
  Future<void> _openScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (scannedCode == null || !mounted) return;

    // Use the service to find the team by its code
    final team = await _dbService.getTeamByCode(scannedCode);

    if (team == null) {
      showFeedbackSnackbar(
        context,
        'Error: Team code "$scannedCode" not found.',
        type: FeedbackType.error,
      );
      return;
    }

    // Navigate to the check-in screen and refresh the dashboard when we return
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AttendanceCheckInScreen(
            teamId: team['id'],
            teamName: team['team_name'],
          ),
        ),
      );
      // Refresh the stats after closing the check-in screen
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No participant data found.'));
          }

          final participants = snapshot.data!;

          // Calculate stats
          final totalParticipants = participants.length;
          final presentParticipants = participants
              .where((p) => p['is_present'] == true)
              .length;
          final totalTeams = participants
              .map((p) => p['registrations']['id'])
              .toSet()
              .length;
          final presentTeams = participants
              .where((p) => p['is_present'] == true)
              .map((p) => p['registrations']['id'])
              .toSet()
              .length;

          return ListView(
            children: [
              Row(
                children: [
                  Text(
                    'Attendance Overview',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    tooltip: 'Refresh Data',
                    onPressed: _refreshData,
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: _openScanner,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan for Attendance'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: [
                  StatCard(
                    title: 'Participants Present',
                    value: '$presentParticipants / $totalParticipants',
                    icon: Icons.person_add_outlined,
                    color: Colors.green.shade700,
                  ),
                  StatCard(
                    title: 'Teams Present',
                    value: '$presentTeams / $totalTeams',
                    icon: Icons.group_work,
                    color: Colors.blue.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // We can add the team status data table here later if needed
            ],
          );
        },
      ),
    );
  }
}

// You can move this StatCard to a shared file later
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20.0),
        width: 280,
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
