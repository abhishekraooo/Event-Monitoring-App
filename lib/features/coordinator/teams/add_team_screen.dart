// lib/features/coordinator/teams/add_team_screen.dart

import 'package:event_management_app/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:event_management_app/core/services/database_service.dart';

class AddTeamScreen extends StatefulWidget {
  const AddTeamScreen({super.key});
  @override
  State<AddTeamScreen> createState() => _AddTeamScreenState();
}

class _AddTeamScreenState extends State<AddTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  bool _isLoading = false;

  // Controllers for team data
  final _teamCodeController = TextEditingController();
  final _teamNameController = TextEditingController();
  final _ideaTitleController = TextEditingController();
  final _ideaAbstractController = TextEditingController();

  // Controllers for participants
  final _leadNameController = TextEditingController();
  final _member1NameController = TextEditingController();
  final _member2NameController = TextEditingController();
  final _member3NameController = TextEditingController();
  // Add more controllers for other participant details if needed (email, etc.)

  @override
  void dispose() {
    _teamCodeController.dispose();
    _teamNameController.dispose();
    _ideaTitleController.dispose();
    _ideaAbstractController.dispose();
    _leadNameController.dispose();
    _member1NameController.dispose();
    _member2NameController.dispose();
    _member3NameController.dispose();
    super.dispose();
  }

  Future<void> _saveTeam() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    // Build the list of participants to send to the database
    final List<Map<String, dynamic>> participants = [];
    // Add team lead
    participants.add({
      'name': _leadNameController.text.trim(),
      'is_team_lead': true,
    });
    // Add members only if their name is not empty
    if (_member1NameController.text.trim().isNotEmpty) {
      participants.add({
        'name': _member1NameController.text.trim(),
        'is_team_lead': false,
      });
    }
    if (_member2NameController.text.trim().isNotEmpty) {
      participants.add({
        'name': _member2NameController.text.trim(),
        'is_team_lead': false,
      });
    }
    if (_member3NameController.text.trim().isNotEmpty) {
      participants.add({
        'name': _member3NameController.text.trim(),
        'is_team_lead': false,
      });
    }

    // Build the final data object
    final teamData = {
      'team_code': _teamCodeController.text.trim(),
      'team_name': _teamNameController.text.trim(),
      'idea_title': _ideaTitleController.text.trim(),
      'idea_abstract': _ideaAbstractController.text.trim(),
      'participants': participants,
    };

    try {
      await _dbService.createNewTeam(teamData);
      if (mounted) {
        showFeedbackSnackbar(
          context,
          'Team created successfully!',
          type: FeedbackType.success,
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        showFeedbackSnackbar(
          context,
          'Error creating team: $e',
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
        title: const Text('Add New Team'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveTeam,
              icon: _isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Team'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionCard('Team Details', [
              TextFormField(
                controller: _teamCodeController,
                decoration: const InputDecoration(
                  labelText: 'Team Code (e.g., IC-XXX)',
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _teamNameController,
                decoration: const InputDecoration(labelText: 'Team Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _ideaTitleController,
                decoration: const InputDecoration(
                  labelText: 'Idea Title (Optional)',
                ),
              ),
              TextFormField(
                controller: _ideaAbstractController,
                decoration: const InputDecoration(
                  labelText: 'Idea Abstract (Optional)',
                ),
                maxLines: 4,
              ),
            ]),
            _buildSectionCard('Participants', [
              TextFormField(
                controller: _leadNameController,
                decoration: const InputDecoration(labelText: 'Team Lead Name'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _member1NameController,
                decoration: const InputDecoration(
                  labelText: 'Member 1 Name (Optional)',
                ),
              ),
              TextFormField(
                controller: _member2NameController,
                decoration: const InputDecoration(
                  labelText: 'Member 2 Name (Optional)',
                ),
              ),
              TextFormField(
                controller: _member3NameController,
                decoration: const InputDecoration(
                  labelText: 'Member 3 Name (Optional)',
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(String title, List<Widget> fields) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const Divider(height: 20),
            ...fields.map(
              (f) =>
                  Padding(padding: const EdgeInsets.only(bottom: 8), child: f),
            ),
          ],
        ),
      ),
    );
  }
}
