// lib/features/coordinator/attendance/team_check_in_screen.dart

import 'package:flutter/material.dart';
import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/core/utils/snackbar_utils.dart';

// DEFINED ENUM: To control the screen's mode (Attendance vs. Food).
enum CheckInMode { attendance, food }

class TeamCheckInScreen extends StatefulWidget {
  final int teamId;
  final String teamName;
  final String teamCode;
  final CheckInMode mode; // ADDED: The mode is now a required parameter

  const TeamCheckInScreen({
    super.key,
    required this.teamId,
    required this.teamName,
    required this.teamCode,
    required this.mode, // ADDED
  });

  @override
  State<TeamCheckInScreen> createState() => _TeamCheckInScreenState();
}

class _TeamCheckInScreenState extends State<TeamCheckInScreen> {
  final DatabaseService _dbService = DatabaseService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _participants = [];
  final Map<int, bool> _draftAttendance = {};
  final Map<int, bool> _draftLunch = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final participants = await _dbService.getParticipantsForTeam(
        widget.teamId,
      );
      if (mounted) {
        setState(() {
          _participants = participants;
          // Initialize draft state from fetched data
          for (var p in _participants) {
            _draftAttendance[p['id']] = p['is_present'];
            _draftLunch[p['id']] = p['lunch_claimed'];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(
          context,
          'Error loading data: $e',
          type: FeedbackType.error,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<bool> _showTurnOffConfirmation() async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Action'),
        content: const Text(
          'Are you sure you want to mark this as NOT complete?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  void _onToggleChanged(int participantId, bool newValue, String type) async {
    bool allowChange = true;
    // If turning OFF, show confirmation
    if (newValue == false) {
      allowChange = await _showTurnOffConfirmation();
    }

    if (allowChange) {
      setState(() {
        if (type == 'attendance') {
          _draftAttendance[participantId] = newValue;
        } else {
          _draftLunch[participantId] = newValue;
        }
        _hasChanges = true; // A change has been made, so show the save button
      });
    }
  }

  Future<void> _saveChanges() async {
    setState(() => _isLoading = true);

    // Prepare only the data that has changed
    final List<Map<String, dynamic>> updates = [];
    for (var p in _participants) {
      final int id = p['id'];
      final bool newAttendance = _draftAttendance[id]!;
      final bool newLunch = _draftLunch[id]!;
      // Only add to the update list if something actually changed
      if (newAttendance != p['is_present'] || newLunch != p['lunch_claimed']) {
        updates.add({
          'id': id,
          'is_present': newAttendance,
          'lunch_claimed': newLunch,
        });
      }
    }

    if (updates.isEmpty) {
      Navigator.pop(context);
      return;
    }

    try {
      await _dbService.bulkUpdateParticipantStatus(updates);
      if (mounted) {
        showFeedbackSnackbar(
          context,
          'Changes saved successfully!',
          type: FeedbackType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(
          context,
          'Error saving changes: $e',
          type: FeedbackType.error,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // This now correctly uses the 'mode' passed to the widget
        title: Text(
          widget.mode == CheckInMode.attendance ? 'Attendance' : 'Food Count',
        ),
      ),
      floatingActionButton: _hasChanges
          ? FloatingActionButton.extended(
              onPressed: _isLoading ? null : _saveChanges,
              label: const Text('Save Changes'),
              icon: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Icon(Icons.save),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.teamName,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.teamCode,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                _buildSection('Attendance', 'attendance'),
                const SizedBox(height: 16),
                _buildSection('Food Count', 'lunch'),
              ],
            ),
    );
  }

  Widget _buildSection(String title, String type) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            // FIX: Added .toList() to convert the map to a list of widgets.
            ..._participants.map((p) {
              final statusMap = type == 'attendance'
                  ? _draftAttendance
                  : _draftLunch;
              return SwitchListTile(
                title: Text(p['name'] ?? 'No Name'),
                subtitle: Text(p['college'] ?? 'No College'),
                value: statusMap[p['id']] ?? false,
                onChanged: (newValue) =>
                    _onToggleChanged(p['id'], newValue, type),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
