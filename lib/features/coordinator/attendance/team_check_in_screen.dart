// lib/features/coordinator/attendance/team_check_in_screen.dart

import 'package:flutter/material.dart';
import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/core/utils/snackbar_utils.dart';

// The enum to control the screen's mode (Attendance vs. Food).
enum CheckInMode { attendance, food }

class TeamCheckInScreen extends StatefulWidget {
  final int teamId;
  final String teamName;
  final String teamCode;
  final CheckInMode mode;

  const TeamCheckInScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.teamCode,
    required this.mode,
  });

  @override
  State<TeamCheckInScreen> createState() => _TeamCheckInScreenState();
}

class _TeamCheckInScreenState extends State<TeamCheckInScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<Map<String, dynamic>>> _participantsFuture;

  late String _title;
  late String _dbColumn;

  @override
  void initState() {
    super.initState();
    _participantsFuture = _dbService.getParticipantsForTeam(widget.teamId);

    // Set screen properties based on the mode
    switch (widget.mode) {
      case CheckInMode.attendance:
        _title = 'Attendance: ${widget.teamName}';
        _dbColumn = 'is_present';
        break;
      case CheckInMode.food:
        _title = 'Food Count: ${widget.teamName}';
        _dbColumn = 'lunch_claimed';
        break;
    }
  }

  Future<void> _updateStatus(int participantId, bool newStatus) async {
    try {
      // This uses the simpler updateParticipant method
      await _dbService.updateParticipant(participantId, {_dbColumn: newStatus});
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(
          context,
          'Error updating status: $e',
          type: FeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _participantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No participants found for this team.'),
            );
          }

          final participants = snapshot.data!;

          return ListView.builder(
            itemCount: participants.length,
            itemBuilder: (context, index) {
              final participant = participants[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  title: Text(
                    participant['name'] ?? 'No Name',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(participant['college'] ?? 'No College'),
                  trailing: Switch(
                    value: participant[_dbColumn] ?? false,
                    onChanged: (newValue) {
                      setState(() {
                        // Optimistically update the UI
                        participant[_dbColumn] = newValue;
                      });
                      // Trigger the database update
                      _updateStatus(participant['id'], newValue);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
