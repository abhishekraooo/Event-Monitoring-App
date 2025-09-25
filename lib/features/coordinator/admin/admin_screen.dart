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
  _AdminDataSource? _dataSource;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final teamsFuture = supabase
          .from('registrations')
          .select()
          .order('team_code', ascending: true);
      final coordinatorsFuture = _dbService.getAllCoordinators();
      final results = await Future.wait([teamsFuture, coordinatorsFuture]);
      if (mounted) {
        setState(() {
          _allTeams = results[0] as List<Map<String, dynamic>>;
          _allCoordinators = results[1] as List<Map<String, dynamic>>;
          _dataSource = _createDataSource();
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

  _AdminDataSource _createDataSource() {
    return _AdminDataSource(
      teams: _allTeams,
      coordinators: _allCoordinators,
      selectedTeamIds: _selectedTeamIds,
      onSelectChanged: (teamId, isSelected) {
        setState(() {
          if (isSelected == true) {
            _selectedTeamIds.add(teamId);
          } else {
            _selectedTeamIds.remove(teamId);
          }
        });
      },
    );
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
                child: Text('-- Unassign --'),
              ),
              ..._allCoordinators.map((c) {
                // FIX: Added a null check to handle coordinators with no name.
                final coordinatorName =
                    c['full_name'] as String? ?? 'Unnamed Coordinator';
                return DropdownMenuItem<String>(
                  value: c['id'],
                  child: Text(coordinatorName),
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
      setState(() => _selectedTeamIds.clear());
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoading) {
      _dataSource = _createDataSource();
    }
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Row(
          children: [
            Text(
              'Admin Panel',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _selectedTeamIds.isEmpty
                  ? null
                  : _showAssignmentDialog,
              icon: const Icon(Icons.assignment_ind_outlined),
              label: Text('Assign (${_selectedTeamIds.length})'),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
              onPressed: _fetchData,
            ),
          ],
        ),
        const SizedBox(height: 24),
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : PaginatedDataTable(
                header: Text('All Teams (${_allTeams.length})'),
                rowsPerPage: 20,
                showCheckboxColumn: true,
                columns: const [
                  DataColumn(label: Text('Team Code')),
                  DataColumn(label: Text('Team Name')),
                  DataColumn(label: Text('Assigned Coordinator')),
                ],
                source: _dataSource!,
              ),
      ],
    );
  }
}

// Data source for the admin paginated table
class _AdminDataSource extends DataTableSource {
  final List<Map<String, dynamic>> teams;
  final List<Map<String, dynamic>> coordinators;
  final Set<int> selectedTeamIds;
  final Function(int, bool?) onSelectChanged;

  _AdminDataSource({
    required this.teams,
    required this.coordinators,
    required this.selectedTeamIds,
    required this.onSelectChanged,
  });

  String _getCoordinatorName(String? coordinatorId) {
    if (coordinatorId == null) return 'Unassigned';
    return coordinators.firstWhere(
      (c) => c['id'] == coordinatorId,
      orElse: () => {'full_name': 'Unknown'},
    )['full_name'];
  }

  @override
  DataRow? getRow(int index) {
    if (index >= teams.length) return null;
    final team = teams[index];
    final teamId = team['id'] as int;

    return DataRow(
      selected: selectedTeamIds.contains(teamId),
      onSelectChanged: (isSelected) => onSelectChanged(teamId, isSelected),
      cells: [
        DataCell(Text(team['team_code'] ?? '')),
        DataCell(Text(team['team_name'] ?? '')),
        DataCell(Text(_getCoordinatorName(team['assigned_coordinator_id']))),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => teams.length;

  @override
  int get selectedRowCount => selectedTeamIds.length;
}
