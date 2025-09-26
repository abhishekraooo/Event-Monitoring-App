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
        showFeedbackSnackbar(
          context,
          'Error loading data: $e',
          type: FeedbackType.error,
        );
        setState(() => _isLoading = false);
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

  Future<void> _showEditDialog(
    Map<String, dynamic> participantData,
    String title,
  ) async {
    final formKey = GlobalKey<FormState>();
    final Map<String, TextEditingController> controllers = {
      'name': TextEditingController(text: participantData['name']),
      'email': TextEditingController(text: participantData['email']),
      'number': TextEditingController(text: participantData['number']),
      'college': TextEditingController(text: participantData['college']),
      'branch': TextEditingController(text: participantData['branch']),
      'semester': TextEditingController(text: participantData['semester']),
    };

    final bool? didSaveChanges = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit $title'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: controllers.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
                    controller: entry.value,
                    decoration: InputDecoration(
                      labelText: entry.key.replaceFirst(
                        entry.key[0],
                        entry.key[0].toUpperCase(),
                      ),
                    ),
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
                  dataToUpdate[key] = controller.text.trim();
                });
                try {
                  await _dbService.updateParticipant(
                    participantData['id'],
                    dataToUpdate,
                  );
                  if (mounted) Navigator.of(context).pop(true);
                } catch (e) {
                  if (mounted)
                    showFeedbackSnackbar(
                      context,
                      'Error: $e',
                      type: FeedbackType.error,
                    );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    // Dispose controllers after dialog is closed
    for (var controller in controllers.values) {
      controller.dispose();
    }
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

    final participants = (_teamData!['participants'] as List<dynamic>)
        .cast<Map<String, dynamic>>();
    participants.sort(
      (a, b) => (a['is_team_lead'] == true) ? -1 : 1,
    ); // Ensure lead is always first

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
            _buildSectionCard('Idea', {
              'Title': _teamData!['idea_title'],
              'Abstract': _teamData!['idea_abstract'],
            }, null),
            ...participants.map((participant) {
              final title = (participant['is_team_lead'] == true)
                  ? 'Team Lead'
                  : 'Member';
              final details = {
                'Name': participant['name'],
                'Email': participant['email'],
                'Number': participant['number'],
                'College': participant['college'],
                'Branch': participant['branch'],
                'Semester': participant['semester'],
              };
              return _buildSectionCard(title, details, participant);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    Map<String, dynamic> details,
    Map<String, dynamic>? participantData,
  ) {
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
                        showFeedbackSnackbar(context, 'Copied to clipboard!');
                      },
                    ),
                    if (_userRole == 'admin' && participantData != null)
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                        tooltip: 'Edit Details',
                        onPressed: () =>
                            _showEditDialog(participantData, title),
                      ),
                  ],
                ),
              ],
            ),
            const Divider(height: 16),
            ...details.entries.map(
              (entry) => _buildDetailRow(entry.key, entry.value?.toString()),
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
