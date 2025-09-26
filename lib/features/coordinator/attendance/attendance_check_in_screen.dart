// lib/features/coordinator/attendance/attendance_check_in_screen.dart

import 'package:flutter/material.dart';
import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/core/utils/snackbar_utils.dart';

class AttendanceCheckInScreen extends StatefulWidget {
  final int teamId;
  final String teamName;

  const AttendanceCheckInScreen({
    super.key,
    required this.teamId,
    required this.teamName,
  });

  @override
  State<AttendanceCheckInScreen> createState() =>
      _AttendanceCheckInScreenState();
}

class _AttendanceCheckInScreenState extends State<AttendanceCheckInScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<Map<String, dynamic>>> _participantsFuture;

  @override
  void initState() {
    super.initState();
    _participantsFuture = _dbService.getParticipantsForTeam(widget.teamId);
  }

  Future<void> _updateAttendance(int participantId, bool isPresent) async {
    try {
      await _dbService.updateParticipant(participantId, {
        'is_present': isPresent,
      });
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(
          context,
          'Error updating attendance: $e',
          type: FeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Attendance: ${widget.teamName}')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _participantsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                    value: participant['is_present'] ?? false,
                    onChanged: (newValue) {
                      setState(() {
                        // Optimistically update the UI
                        participant['is_present'] = newValue;
                      });
                      // Trigger the database update
                      _updateAttendance(participant['id'], newValue);
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
