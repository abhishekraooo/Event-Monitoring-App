// lib/features/coordinator/teams/team_detail_screen.dart

import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TeamDetailScreen extends StatefulWidget {
  final int teamId;
  const TeamDetailScreen({super.key, required this.teamId});

  @override
  State<TeamDetailScreen> createState() => _TeamDetailScreenState();
}

class _TeamDetailScreenState extends State<TeamDetailScreen> {
  final DatabaseService _dbService = DatabaseService();
  Map<String, dynamic>? _teamData;
  String? _userRole;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final teamData = await _dbService.getTeamById(widget.teamId);
      final userRole = await _dbService.getCurrentUserRole();
      if (mounted) {
        setState(() {
          _teamData = teamData;
          _userRole = userRole;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        // REFACTORED to use the new utility
        showFeedbackSnackbar(
          context,
          'Error loading data: $e',
          type: FeedbackType.error,
        );
      }
    }
  }

  String _formatDetailsForCopy(Map<String, dynamic> details) {
    return details.entries
        .where(
          (entry) => entry.value != null && entry.value.toString().isNotEmpty,
        )
        .map((entry) => '${entry.key}: ${entry.value}')
        .join('\n');
  }

  // NEW: Method to show the editing dialog
  Future<void> _showEditDialog(
    String title,
    Map<String, dynamic> sectionData,
  ) async {
    final formKey = GlobalKey<FormState>();
    final controllers = {
      for (var entry in sectionData.entries)
        entry.key: TextEditingController(text: entry.value?.toString() ?? ''),
    };

    final bool? didSaveChanges = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit $title'),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: sectionData.keys.map((key) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: TextFormField(
                      controller: controllers[key],
                      decoration: InputDecoration(labelText: key),
                      maxLines: key.toLowerCase().contains('abstract') ? 5 : 1,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (formKey.currentState?.validate() ?? false) {
                  final dataToUpdate = <String, dynamic>{};
                  controllers.forEach((key, controller) {
                    // This finds the original DB column name, e.g., 'Name' -> 'team_lead_name'
                    final originalKey = _teamData!.keys.firstWhere(
                      (k) => k.endsWith(key.toLowerCase().replaceAll(' ', '_')),
                      orElse: () => '',
                    );
                    if (originalKey.isNotEmpty) {
                      dataToUpdate[originalKey] = controller.text.trim();
                    }
                  });

                  try {
                    await _dbService.updateRegistration(
                      _teamData!['id'],
                      dataToUpdate,
                    );
                    if (mounted) Navigator.of(context).pop(true);
                  } catch (e) {
                    if (mounted)
                      showFeedbackSnackbar(
                        context,
                        'Error: ${e.toString()}',
                        type: FeedbackType.error,
                      );
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (didSaveChanges == true) {
      showFeedbackSnackbar(
        context,
        '$title details updated successfully!',
        type: FeedbackType.success,
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_teamData == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Could not load team data.')),
      );
    }

    // Data maps for each section
    final ideaDetails = {
      'Title': _teamData!['idea_title'],
      'Abstract': _teamData!['idea_abstract'],
    };
    final leadDetails = {
      'Name': _teamData!['team_lead_name'],
      'Email': _teamData!['team_lead_email'],
      'Number': _teamData!['team_lead_number'],
      'College': _teamData!['team_lead_college'],
      'Branch': _teamData!['team_lead_branch'],
      'Semester': _teamData!['team_lead_semester'],
    };
    final member1Details = {
      'Name': _teamData!['member_1_name'],
      'Email': _teamData!['member_1_email'],
      'Number': _teamData!['member_1_number'],
      'College': _teamData!['member_1_college'],
      'Branch': _teamData!['member_1_branch'],
      'Semester': _teamData!['member_1_semester'],
    };
    final member2Details = {
      'Name': _teamData!['member_2_name'],
      'Email': _teamData!['member_2_email'],
      'Number': _teamData!['member_2_number'],
      'College': _teamData!['member_2_college'],
      'Branch': _teamData!['member_2_branch'],
      'Semester': _teamData!['member_2_semester'],
    };
    final member3Details = {
      'Name': _teamData!['member_3_name'],
      'Email': _teamData!['member_3_email'],
      'Number': _teamData!['member_3_number'],
      'College': _teamData!['member_3_college'],
      'Branch': _teamData!['member_3_branch'],
      'Semester': _teamData!['member_3_semester'],
    };

    return Scaffold(
      appBar: AppBar(title: Text(_teamData!['team_code'] ?? 'Team Details')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Text(
                _teamData!['team_name'] ?? 'Team Details',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            _buildSectionCard('Idea', ideaDetails),
            _buildSectionCard('Team Lead', leadDetails),

            if (_teamData!['member_1_name'] != null &&
                _teamData!['member_1_name'].isNotEmpty)
              _buildSectionCard('Member 1', member1Details),

            if (_teamData!['member_2_name'] != null &&
                _teamData!['member_2_name'].isNotEmpty)
              _buildSectionCard('Member 2', member2Details),

            if (_teamData!['member_3_name'] != null &&
                _teamData!['member_3_name'].isNotEmpty)
              _buildSectionCard('Member 3', member3Details),
          ],
        ),
      ),
    );
  }

  // Updated _buildSectionCard to include a conditional edit button
  Widget _buildSectionCard(String title, Map<String, dynamic> details) {
    final copyableText = _formatDetailsForCopy(details);

    return Card(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.copy_outlined,
                        size: 20,
                        color: Colors.grey,
                      ),
                      tooltip: 'Copy Details',
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: copyableText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copied to clipboard!')),
                        );
                      },
                    ),
                    // NEW: Conditional Edit Button
                    if (_userRole == 'admin')
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                        tooltip: 'Edit Details',
                        onPressed: () => _showEditDialog(title, details),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            ...details.entries.map(
              (entry) => _buildDetailRow(entry.key, entry.value.toString()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String? value) {
    if (value == null || value.isEmpty || value == 'null') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$title:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
