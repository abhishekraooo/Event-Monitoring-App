// lib/features/coordinator/dashboard/dashboard_screen.dart
import 'package:event_management_app/main.dart';
import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Future<List<Map<String, dynamic>>> _registrationsFuture;

  @override
  void initState() {
    super.initState();
    _registrationsFuture = _fetchRegistrations();
  }

  Future<List<Map<String, dynamic>>> _fetchRegistrations() async {
    // We get all active teams, sorted by code
    return await supabase
        .from('registrations')
        .select()
        .eq('status', 'active')
        .order('team_code', ascending: true)
        .limit(10000);
  }

  // Helper function to calculate team size
  int _getTeamSize(Map<String, dynamic> team) {
    int count = 0;
    if (team['team_lead_name'] != null) count++;
    if (team['member_1_name'] != null &&
        (team['member_1_name'] as String).isNotEmpty)
      count++;
    if (team['member_2_name'] != null &&
        (team['member_2_name'] as String).isNotEmpty)
      count++;
    if (team['member_3_name'] != null &&
        (team['member_3_name'] as String).isNotEmpty)
      count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _registrationsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.black),
          );
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No registration data found.'));
        }

        final registrations = snapshot.data!;

        // --- STATS CALCULATION ---
        final totalTeams = registrations.length;
        final checkedInTeams = registrations
            .where((t) => t['is_checked_in'] == true)
            .length;
        final abstractsSubmitted = registrations
            .where(
              (t) =>
                  t['idea_abstract'] != null &&
                  (t['idea_abstract'] as String).isNotEmpty,
            )
            .length;
        final soloTeams = registrations
            .where((t) => t['participation_format'] == 'Solo')
            .length;

        // NEW: Calculate total participants by summing up the size of each team
        final totalParticipants = registrations.fold<int>(
          0,
          (sum, team) => sum + _getTeamSize(team),
        );

        return ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            Text(
              'Event Overview',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16.0,
              runSpacing: 16.0,
              children: [
                StatCard(
                  title: 'Total Teams',
                  value: totalTeams.toString(),
                  icon: Icons.groups,
                  color: Colors.blue.shade700,
                ),
                // NEW: StatCard for Total Participants
                StatCard(
                  title: 'Total Participants',
                  value: totalParticipants.toString(),
                  icon: Icons.person_pin_rounded,
                  color: Colors.teal.shade700,
                ),
                StatCard(
                  title: 'Teams Checked In',
                  value: '$checkedInTeams / $totalTeams',
                  icon: Icons.how_to_reg,
                  color: Colors.green.shade700,
                ),
                StatCard(
                  title: 'Abstracts Submitted',
                  value: '$abstractsSubmitted / $totalTeams',
                  icon: Icons.lightbulb_outline,
                  color: Colors.orange.shade800,
                ),
                StatCard(
                  title: 'Solo Teams',
                  value: soloTeams.toString(),
                  icon: Icons.person,
                  color: Colors.purple.shade700,
                ),
              ],
            ),
            // We removed the divider and other list tiles for now to keep the dashboard focused on stats.
          ],
        );
      },
    );
  }
}

// Reusable StatCard widget
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
