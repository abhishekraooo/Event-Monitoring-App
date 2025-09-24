// lib/features/coordinator/teams/team_detail_screen.dart

import 'package:event_management_app/core/services/database_service.dart';
import 'package:flutter/material.dart';

class TeamDetailScreen extends StatefulWidget {
  final int teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<Map<String, dynamic>> _teamDetailsFuture;
  late Future<String> _userRoleFuture;

  @override
  void initState() {
    super.initState();
    // Fetch both the team details and the user's role simultaneously
    _teamDetailsFuture = _dbService.getTeamById(widget.teamId);
    _userRoleFuture = _dbService.getCurrentUserRole();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      // Use a FutureBuilder to wait for both futures to complete
      future: Future.wait([_teamDetailsFuture, _userRoleFuture]),
      builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final teamData = snapshot.data![0] as Map<String, dynamic>;
        final userRole = snapshot.data![1] as String;

        return Scaffold(
          appBar: AppBar(title: Text(teamData['team_name'] ?? 'Team Details')),
          floatingActionButton: userRole == 'admin'
              ? FloatingActionButton(
                  onPressed: () {
                    // TODO: Navigate to EditTeamScreen
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit screen coming soon!')),
                    );
                  },
                  child: const Icon(Icons.edit),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildSectionCard('Idea', [
                _buildDetailRow('Title', teamData['idea_title']),
                _buildDetailRow('Abstract', teamData['idea_abstract']),
              ]),
              _buildSectionCard('Team Lead', [
                _buildDetailRow('Name', teamData['team_lead_name']),
                _buildDetailRow('Email', teamData['team_lead_email']),
                _buildDetailRow('Number', teamData['team_lead_number']),
                _buildDetailRow('College', teamData['team_lead_college']),
              ]),
              if (teamData['member_1_name'] != null)
                _buildSectionCard('Member 1', [
                  _buildDetailRow('Name', teamData['member_1_name']),
                  _buildDetailRow('Email', teamData['member_1_email']),
                  _buildDetailRow('Number', teamData['member_1_number']),
                ]),
              // Add similar cards for member_2 and member_3 if they exist
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionCard(String title, List<Widget> details) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20),
            ...details,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }
}
