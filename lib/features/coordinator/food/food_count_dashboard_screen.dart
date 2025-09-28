// lib/features/coordinator/food/food_count_dashboard_screen.dart

import 'package:event_management_app/features/coordinator/attendance/team_check_in_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/core/utils/snackbar_utils.dart';
import 'package:event_management_app/features/coordinator/attendance/member_status_screen.dart';
import 'package:event_management_app/features/coordinator/scanner/qr_scanner_screen.dart';

class FoodCountDashboardScreen extends StatefulWidget {
  const FoodCountDashboardScreen({super.key});
  @override
  State<FoodCountDashboardScreen> createState() =>
      _FoodCountDashboardScreenState();
}

class _FoodCountDashboardScreenState extends State<FoodCountDashboardScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<Map<String, dynamic>>> _participantsFuture;

  @override
  void initState() {
    super.initState();
    _participantsFuture = _dbService.getParticipantStats();
  }

  Future<void> _refreshData() async {
    setState(() {
      _participantsFuture = _dbService.getParticipantStats();
    });
  }

  Future<void> _openScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );
    if (scannedCode == null || !mounted) return;
    final team = await _dbService.getTeamByCode(scannedCode);
    if (team == null) {
      showFeedbackSnackbar(
        context,
        'Error: Team code "$scannedCode" not found.',
        type: FeedbackType.error,
      );
      return;
    }
    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TeamCheckInScreen(
            teamId: team['id'],
            teamName: team['team_name'],
            teamCode: team['team_code'],
            mode: CheckInMode.food, // Pass the correct mode
          ),
        ),
      );
      _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _participantsFuture,
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
          final totalParticipants = participants.length;
          final lunchesServed = participants
              .where((p) => p['lunch_claimed'] == true)
              .length;

          return ListView(
            children: [
              Row(
                children: [
                  Text(
                    'Food Count',
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
                    label: const Text('Scan for Lunch'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              StatCard(
                title: 'Lunches Served',
                value: '$lunchesServed / $totalParticipants',
                icon: Icons.restaurant,
                color: Colors.brown.shade700,
              ),
            ],
          );
        },
      ),
    );
  }
}

// FIX: The full implementation of the StatCard widget is now included.
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
