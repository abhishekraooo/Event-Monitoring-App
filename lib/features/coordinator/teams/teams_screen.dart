// lib/features/coordinator/teams/teams_screen.dart

import 'dart:async';
import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/core/utils/snackbar_utils.dart';
import 'package:event_management_app/features/coordinator/teams/add_team_screen.dart';
import 'package:event_management_app/features/coordinator/teams/team_detail_screen.dart';
import 'package:flutter/material.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});
  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final DatabaseService _dbService = DatabaseService();
  List<Map<String, dynamic>> _allRegistrations = [];
  List<Map<String, dynamic>> _filteredRegistrations = [];
  bool _isLoading = true;
  String _userRole = 'coordinator';
  _TeamDataSource? _dataSource;

  final _searchController = TextEditingController();
  Timer? _debounce;

  int _firstRowIndex = 0;

  @override
  void initState() {
    super.initState();
    _fetchRegistrations();
    _searchController.addListener(_filterRegistrations);
  }

  Future<void> _fetchRegistrations() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final role = await _dbService.getCurrentUserRole();
      final data = await _dbService.getTeamsWithLeads();
      if (mounted) {
        setState(() {
          _userRole = role;
          _allRegistrations = data;
          _filterRegistrations(isFetching: true);
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

  void _filterRegistrations({bool isFetching = false}) {
    if (isFetching) {
      _performFilter();
      return;
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 400),
      () => _performFilter(),
    );
  }

  void _performFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRegistrations = _allRegistrations.where((team) {
        final leadName = (team['participants'] as List).isNotEmpty
            ? (team['participants'][0]['name'] as String? ?? '')
            : '';
        return (team['team_name'] as String? ?? '').toLowerCase().contains(
              query,
            ) ||
            (team['team_code'] as String? ?? '').toLowerCase().contains(
              query,
            ) ||
            leadName.toLowerCase().contains(query);
      }).toList();
      _dataSource = _createDataSource();
    });
  }

  _TeamDataSource _createDataSource() {
    return _TeamDataSource(
      data: _filteredRegistrations,
      userRole: _userRole,
      // UPDATED: Navigation logic is now smarter
      onTapRow: (teamId) async {
        final didSaveChanges = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => TeamDetailScreen(teamId: teamId),
          ),
        );
        // Only refresh the data if the detail screen returns 'true' after an edit
        if (didSaveChanges == true) {
          _fetchRegistrations();
        }
      },
      onDelete: (team) => _showDeleteConfirmation(team),
    );
  }

  Future<void> _showDeleteConfirmation(Map<String, dynamic> team) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to delete Team "${team['team_name']}"? This will mark the team as inactive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbService.deleteTeam(team['id']);
        showFeedbackSnackbar(
          context,
          'Team deleted successfully!',
          type: FeedbackType.success,
        );
        _fetchRegistrations();
      } catch (e) {
        showFeedbackSnackbar(context, 'Error: $e', type: FeedbackType.error);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'All Registrations',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // UPDATED: Replaced scanner icon with Add Team icon
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTeamScreen(),
                  ),
                ).then(
                  (_) => _fetchRegistrations(),
                ); // Refresh after potentially adding a new team
              },
              icon: const Icon(Icons.group_add_outlined),
              iconSize: 32,
              tooltip: 'Add New Team',
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Search by Team, Code, or Lead',
                  prefixIcon: Icon(Icons.search),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh Data',
              onPressed: _fetchRegistrations,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(color: Colors.black),
                ),
              )
            : PaginatedDataTable(
                header: Text(
                  'Registered Teams (${_filteredRegistrations.length})',
                ),
                rowsPerPage: 20,
                // NEW: Restore the table to the last viewed page
                initialFirstRowIndex: _firstRowIndex,
                // NEW: Save the page index when the user changes pages
                onPageChanged: (rowIndex) {
                  setState(() {
                    _firstRowIndex = rowIndex;
                  });
                },
                showCheckboxColumn: false,
                columns: [
                  const DataColumn(label: Text('Team Code')),
                  const DataColumn(label: Text('Team Name')),
                  const DataColumn(label: Text('Lead Name')),
                  const DataColumn(label: Text('College')),
                  const DataColumn(label: Text('Checked In')),
                  const DataColumn(label: Text('Abstract')),
                  if (_userRole == 'admin')
                    const DataColumn(label: Text('Actions')),
                ],
                source: _dataSource!,
              ),
      ],
    );
  }
}

class _TeamDataSource extends DataTableSource {
  final List<Map<String, dynamic>> data;
  final String userRole;
  final Function(int teamId) onTapRow;
  final Function(Map<String, dynamic> team) onDelete;

  _TeamDataSource({
    required this.data,
    required this.userRole,
    required this.onTapRow,
    required this.onDelete,
  });

  @override
  DataRow? getRow(int index) {
    if (index >= data.length) return null;
    final team = data[index];
    final leadData = (team['participants'] as List).isNotEmpty
        ? team['participants'][0] as Map<String, dynamic>
        : {'name': 'N/A', 'college': 'N/A'};
    final hasAbstract =
        team['idea_abstract'] != null &&
        (team['idea_abstract'] as String).isNotEmpty;

    return DataRow(
      onSelectChanged: (selected) {
        if (selected == true) onTapRow(team['id']);
      },
      cells: [
        DataCell(Text(team['team_code'] ?? '')),
        DataCell(Text(team['team_name'] ?? '')),
        DataCell(Text(leadData['name'] ?? '')),
        DataCell(Text(leadData['college'] ?? '')),
        DataCell(
          Icon(
            team['is_checked_in'] == true ? Icons.check_circle : Icons.cancel,
            color: team['is_checked_in'] == true ? Colors.green : Colors.grey,
          ),
        ),
        DataCell(
          Icon(
            hasAbstract ? Icons.check_circle : Icons.cancel,
            color: hasAbstract ? Colors.green : Colors.grey,
          ),
        ),
        if (userRole == 'admin')
          DataCell(
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Delete Team',
              onPressed: () => onDelete(team),
            ),
          ),
      ],
    );
  }

  @override
  bool get isRowCountApproximate => false;
  @override
  int get rowCount => data.length;
  @override
  int get selectedRowCount => 0;
}
