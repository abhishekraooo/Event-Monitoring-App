// lib/features/coordinator/attendance/member_status_screen.dart

import 'package:flutter/material.dart';
import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/core/utils/snackbar_utils.dart';

enum StatusMode { attendance, food }

class MemberStatusScreen extends StatefulWidget {
  final int teamId;
  final String teamName;
  final StatusMode mode;

  const MemberStatusScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.mode,
  });

  @override
  State<MemberStatusScreen> createState() => _MemberStatusScreenState();
}

class _MemberStatusScreenState extends State<MemberStatusScreen> {
  final DatabaseService _dbService = DatabaseService();
  late Future<List<Map<String, dynamic>>> _participantsFuture;

  late String _title;
  late String _dbColumn;

  @override
  void initState() {
    super.initState();
    _participantsFuture = _dbService.getParticipantsForTeam(widget.teamId);

    switch (widget.mode) {
      case StatusMode.attendance:
        _title = 'Attendance: ${widget.teamName}';
        _dbColumn = 'is_present';
        break;
      case StatusMode.food:
        _title = 'Food Count: ${widget.teamName}';
        _dbColumn = 'lunch_claimed';
        break;
    }
  }

  Future<void> _updateStatus(int participantId, bool newStatus) async {
    try {
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
                        participant[_dbColumn] = newValue;
                      });
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
