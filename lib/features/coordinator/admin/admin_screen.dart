// lib/features/coordinator/admin/admin_screen.dart

import 'package:event_management_app/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/main.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _allTeams = [];
  List<Map<String, dynamic>> _allCoordinators = [];
  final Set<int> _selectedTeamIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // Replace your existing _fetchData method with this one.
  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      // This modern syntax fetches both futures and gives us strongly-typed results.
      final (teamsData, coordinatorsData) = await (
        supabase.from('registrations').select().order('team_code'),
        _dbService.getAllCoordinators(),
      ).wait;

      if (mounted) {
        setState(() {
          // No more casting needed, the types are already correct!
          _allTeams = teamsData;
          _allCoordinators = coordinatorsData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(
          context,
          'Error fetching data: $e',
          type: FeedbackType.error,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  String _getCoordinatorName(String? coordinatorId) {
    if (coordinatorId == null) return 'Unassigned';
    return _allCoordinators.firstWhere(
      (c) => c['id'] == coordinatorId,
      orElse: () => {'full_name': 'Unknown'},
    )['full_name'];
  }

  Future<void> _showAssignmentDialog() async {
    String? selectedCoordinatorId;

    final bool? didAssign = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Assign Coordinator to ${_selectedTeamIds.length} Teams'),
          content: DropdownButtonFormField<String>(
            hint: const Text('Select a Coordinator'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Unassign'),
              ),
              ..._allCoordinators.map((c) {
                return DropdownMenuItem<String>(
                  value: c['id'],
                  child: Text(c['full_name']),
                );
              }),
            ],
            onChanged: (value) => selectedCoordinatorId = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  await _dbService.bulkAssignCoordinator(
                    _selectedTeamIds.toList(),
                    selectedCoordinatorId,
                  );
                  if (mounted) Navigator.pop(context, true);
                } catch (e) {
                  if (mounted)
                    showFeedbackSnackbar(
                      context,
                      'Error: $e',
                      type: FeedbackType.error,
                    );
                }
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );

    if (didAssign == true) {
      showFeedbackSnackbar(
        context,
        'Teams updated successfully!',
        type: FeedbackType.success,
      );
      _selectedTeamIds.clear(); // Clear selection after assignment
      _fetchData(); // Refresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Admin Panel',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _selectedTeamIds.isEmpty
                    ? null
                    : _showAssignmentDialog,
                icon: const Icon(Icons.assignment_ind_outlined),
                label: const Text('Assign Selected'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Team Code')),
                        DataColumn(label: Text('Team Name')),
                        DataColumn(label: Text('Assigned Coordinator')),
                      ],
                      rows: _allTeams.map((team) {
                        final teamId = team['id'] as int;
                        return DataRow(
                          selected: _selectedTeamIds.contains(teamId),
                          onSelectChanged: (isSelected) {
                            setState(() {
                              if (isSelected == true) {
                                _selectedTeamIds.add(teamId);
                              } else {
                                _selectedTeamIds.remove(teamId);
                              }
                            });
                          },
                          cells: [
                            DataCell(Text(team['team_code'] ?? '')),
                            DataCell(Text(team['team_name'] ?? '')),
                            DataCell(
                              Text(
                                _getCoordinatorName(
                                  team['assigned_coordinator_id'],
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
