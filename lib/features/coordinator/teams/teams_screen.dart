// lib/features/coordinator/teams/teams_screen.dart

import 'dart:async';
import 'package:event_management_app/core/utils/snackbar_utils.dart';
import 'package:event_management_app/features/coordinator/scanner/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:event_management_app/main.dart';
import 'package:event_management_app/features/coordinator/teams/team_detail_screen.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});
  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  List<Map<String, dynamic>> _allRegistrations = [];
  List<Map<String, dynamic>> _filteredRegistrations = [];
  bool _isLoading = true;

  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _fetchRegistrations();
    _searchController.addListener(_filterRegistrations);
  }

  Future<void> _fetchRegistrations() async {
    if (mounted) setState(() => _isLoading = true);

    // THE FIX: Add .order() to set a default sort order
    final data = await supabase
        .from('registrations')
        .select()
        .order('team_code', ascending: true) // Sort by team_code by default
        .limit(10000);

    if (mounted) {
      setState(() {
        _allRegistrations = data;
        _filterRegistrations(isFetching: true);
        _isLoading = false;
      });
    }
  }

  // REFACTORED: This method is now much cleaner
  Future<void> _openScanner() async {
    final scannedCode = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const QRScannerScreen()),
    );

    if (scannedCode == null || !mounted) return;

    final team = _allRegistrations.firstWhere(
      (t) => t['team_code'] == scannedCode,
      orElse: () => {},
    );
    if (team.isEmpty) {
      showFeedbackSnackbar(
        context,
        'Error: Team code "$scannedCode" not found.',
        type: FeedbackType.error,
      );
      return;
    }
    if (team['is_checked_in'] == true) {
      showFeedbackSnackbar(
        context,
        'Team "${team['team_name']}" is already checked in.',
        type: FeedbackType.info,
      ); // Use .info for neutral messages
      return;
    }

    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Check-in'),
        content: Text(
          'Do you want to check in Team "${team['team_name']}" (${team['team_code']})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Check In'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase
            .from('registrations')
            .update({'is_checked_in': true})
            .eq('team_code', scannedCode);
        showFeedbackSnackbar(
          context,
          'Successfully checked in ${team['team_name']}!',
          type: FeedbackType.success,
        );
        _fetchRegistrations();
      } catch (e) {
        showFeedbackSnackbar(
          context,
          'An error occurred: ${e.toString()}',
          type: FeedbackType.error,
        );
      }
    }
  }

  // Updated to be debounced for better performance
  void _filterRegistrations({bool isFetching = false}) {
    // If we're filtering immediately after a fetch, don't debounce.
    if (isFetching) {
      _performFilter();
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _performFilter();
    });
  }

  void _performFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredRegistrations = _allRegistrations.where((team) {
        return (team['team_name'] as String? ?? '').toLowerCase().contains(
              query,
            ) ||
            (team['team_code'] as String? ?? '').toLowerCase().contains(
              query,
            ) ||
            (team['team_lead_name'] as String? ?? '').toLowerCase().contains(
              query,
            );
      }).toList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'All Registrations',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _openScanner,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Scan to Check In'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // NEW: Search bar and refresh button in a Row
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
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.black),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      // DataTable is now wider for better spacing on web
                      child: DataTable(
                        columnSpacing: 32, // Added spacing
                        // REMOVED: sortColumnIndex and sortAscending
                        columns: const [
                          // REMOVED: onSort callbacks
                          DataColumn(label: Text('Team Code')),
                          DataColumn(label: Text('Team Name')),
                          DataColumn(label: Text('Lead Name')),
                          DataColumn(label: Text('College')),
                          DataColumn(label: Text('Checked In')),
                        ],
                        rows: _filteredRegistrations.map((team) {
                          return DataRow(
                            cells: [
                              DataCell(Text(team['team_code'] ?? '')),
                              DataCell(Text(team['team_name'] ?? '')),
                              DataCell(Text(team['team_lead_name'] ?? '')),
                              DataCell(Text(team['team_lead_college'] ?? '')),
                              DataCell(
                                Icon(
                                  team['is_checked_in'] == true
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: team['is_checked_in'] == true
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                            ],
                            onSelectChanged: (selected) {
                              if (selected == true) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        TeamDetailScreen(teamId: team['id']),
                                  ),
                                );
                              }
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
