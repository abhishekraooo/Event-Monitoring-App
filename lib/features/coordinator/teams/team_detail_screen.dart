// lib/features/coordinator/teams/team_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/core/utils/snackbar_utils.dart';

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

  Future<void> _showEditParticipantDialog(
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

  Future<void> _showEditIdeaDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(
      text: _teamData!['idea_title'],
    );
    final abstractController = TextEditingController(
      text: _teamData!['idea_abstract'],
    );

    final bool? didSaveChanges = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Idea Details'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Idea Title'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: abstractController,
                  decoration: const InputDecoration(labelText: 'Idea Abstract'),
                  maxLines: 5,
                ),
              ],
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
                final dataToUpdate = {
                  'idea_title': titleController.text.trim(),
                  'idea_abstract': abstractController.text.trim(),
                };
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

    titleController.dispose();
    abstractController.dispose();

    if (didSaveChanges == true) {
      showFeedbackSnackbar(
        context,
        'Idea details updated successfully!',
        type: FeedbackType.success,
      );
      _loadData();
    }
  }

  Future<void> _showAddMemberDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final numberController = TextEditingController();

    final bool? didSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Member'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextFormField(
                  controller: numberController,
                  decoration: const InputDecoration(labelText: 'Number'),
                ),
              ],
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
                final newParticipant = {
                  'team_id': widget.teamId,
                  'name': nameController.text.trim(),
                  'email': emailController.text.trim(),
                  'number': numberController.text.trim(),
                  'is_team_lead': false,
                };
                try {
                  await _dbService.addParticipant(newParticipant);
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
            child: const Text('Add Member'),
          ),
        ],
      ),
    );

    nameController.dispose();
    emailController.dispose();
    numberController.dispose();

    if (didSave == true) {
      showFeedbackSnackbar(
        context,
        'New member added successfully!',
        type: FeedbackType.success,
      );
      _loadData();
    }
  }

  Future<void> _showDeleteConfirmationDialog(
    Map<String, dynamic> participantData,
  ) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text(
          'Are you sure you want to remove ${participantData['name']} from this team?',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbService.deleteParticipant(participantData['id']);
        showFeedbackSnackbar(
          context,
          'Member removed successfully!',
          type: FeedbackType.success,
        );
        _loadData();
      } catch (e) {
        showFeedbackSnackbar(context, 'Error: $e', type: FeedbackType.error);
      }
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
    participants.sort((a, b) => (a['is_team_lead'] == true) ? -1 : 1);

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
            }, _teamData),
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
            if (_userRole == 'admin')
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Center(
                  child: ElevatedButton.icon(
                    onPressed: _showAddMemberDialog,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Add New Member'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    String title,
    Map<String, dynamic> details,
    Map<String, dynamic>? dataForEditing,
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
                    if (_userRole == 'admin' && dataForEditing != null)
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          size: 20,
                          color: Colors.grey,
                        ),
                        tooltip: 'Edit Details',
                        onPressed: () {
                          if (title == 'Idea') {
                            _showEditIdeaDialog();
                          } else {
                            _showEditParticipantDialog(dataForEditing, title);
                          }
                        },
                      ),
                    if (_userRole == 'admin' &&
                        dataForEditing != null &&
                        dataForEditing['is_team_lead'] == false)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          size: 20,
                          color: Colors.red,
                        ),
                        tooltip: 'Delete Member',
                        onPressed: () =>
                            _showDeleteConfirmationDialog(dataForEditing),
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

  // UPDATED: This widget's layout has been changed
  Widget _buildDetailRow(String title, String? value) {
    if (value == null || value.isEmpty || value == 'null') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
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
          // The Expanded widget makes sure long text wraps correctly
          Expanded(child: Text(value)),
          // This IconButton is now constrained to take up less space
          IconButton(
            padding: const EdgeInsets.only(
              left: 8.0,
            ), // Add padding only to the left
            constraints:
                const BoxConstraints(), // Removes default large padding
            icon: const Icon(Icons.copy_outlined, size: 18, color: Colors.grey),
            tooltip: 'Copy $title',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              showFeedbackSnackbar(context, '"$title" copied to clipboard!');
            },
          ),
        ],
      ),
    );
  }
}
