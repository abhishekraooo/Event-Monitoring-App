// lib/features/coordinator/teams/edit_team_screen.dart

import 'package:flutter/material.dart';
import 'package:event_management_app/core/services/database_service.dart';

class EditTeamScreen extends StatefulWidget {
  final Map<String, dynamic> initialData;
  const EditTeamScreen({super.key, required this.initialData});

  @override
  State<EditTeamScreen> createState() => _EditTeamScreenState();
}

class _EditTeamScreenState extends State<EditTeamScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dbService = DatabaseService();
  bool _isLoading = false;
  late final Map<String, TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    // THE FIX: Define all editable keys explicitly.
    // This ensures that even if a value is null (like a missing abstract),
    // a controller is still created and a field is shown.
    final List<String> editableKeys = [
      'team_code',
      'team_name',
      'idea_title',
      'idea_abstract',
      'team_lead_name',
      'team_lead_email',
      'team_lead_number',
      'team_lead_college',
      'team_lead_branch',
      'team_lead_semester',
      'member_1_name',
      'member_1_email',
      'member_1_number',
      'member_1_college',
      'member_1_branch',
      'member_1_semester',
      'member_2_name',
      'member_2_email',
      'member_2_number',
      'member_2_college',
      'member_2_branch',
      'member_2_semester',
      'member_3_name',
      'member_3_email',
      'member_3_number',
      'member_3_college',
      'member_3_branch',
      'member_3_semester',
    ];

    _controllers = {
      for (var key in editableKeys)
        key: TextEditingController(
          text: widget.initialData[key]?.toString() ?? '',
        ),
    };
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      final dataToUpdate = <String, dynamic>{};
      _controllers.forEach((key, controller) {
        dataToUpdate[key] = controller.text.trim();
      });

      try {
        await _dbService.updateRegistration(
          widget.initialData['id'],
          dataToUpdate,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Changes saved successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving changes: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit "${widget.initialData['team_name']}"'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton.icon(
              onPressed: _isLoading ? null : _saveChanges,
              icon: _isLoading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_alt_outlined),
              label: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionCard('Team & Idea Details', [
              _buildTextField('team_code', 'Team Code'),
              _buildTextField('team_name', 'Team Name'),
              _buildTextField('idea_title', 'Idea Title'),
              _buildTextField('idea_abstract', 'Idea Abstract', maxLines: 5),
            ]),
            _buildSectionCard('Team Lead Details', [
              _buildTextField('team_lead_name', 'Lead Name'),
              _buildTextField('team_lead_email', 'Lead Email'),
              _buildTextField('team_lead_number', 'Lead Number'),
              _buildTextField('team_lead_college', 'Lead College'),
              _buildTextField('team_lead_branch', 'Lead Branch'),
              _buildTextField('team_lead_semester', 'Lead Semester'),
            ]),
            _buildSectionCard('Member 1 Details', [
              _buildTextField('member_1_name', 'Member 1 Name'),
              _buildTextField('member_1_email', 'Member 1 Email'),
              _buildTextField('member_1_number', 'Member 1 Number'),
              _buildTextField('member_1_semester', 'Member 1 Semester'),
              _buildTextField('member_1_branch', 'Member 1 Branch'),
              _buildTextField('member_1_college', 'Member 1 College'),
            ]),
            _buildSectionCard('Member 2 Details', [
              _buildTextField('member_2_name', 'Member 2 Name'),
              _buildTextField('member_2_email', 'Member 2 Email'),
              _buildTextField('member_2_number', 'Member 2 Number'),
              _buildTextField('member_2_semester', 'Member 2 Semester'),
              _buildTextField('member_2_branch', 'Member 2 Branch'),
              _buildTextField('member_2_college', 'Member 2 College'),
            ]),
            _buildSectionCard('Member 3 Details', [
              _buildTextField('member_3_name', 'Member 3 Name'),
              _buildTextField('member_3_email', 'Member 3 Email'),
              _buildTextField('member_3_number', 'Member 3 Number'),
              _buildTextField('member_3_semester', 'Member 3 Semester'),
              _buildTextField('member_3_branch', 'Member 3 Branch'),
              _buildTextField('member_3_college', 'Member 3 College'),
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
            ...fields,
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String key, String label, {int maxLines = 1}) {
    // This check is still useful for keys that might not be in our editable list
    if (!_controllers.containsKey(key)) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _controllers[key],
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: maxLines > 1,
        ),
        maxLines: maxLines,
        validator: (value) {
          // Make title and abstract optional
          if (key == 'idea_title' || key == 'idea_abstract') {
            return null;
          }
          if (value == null || value.isEmpty) {
            // Only require a name if any other detail for that member exists
            if (key.contains('name') && !_isMemberSectionEmpty(key)) {
              return '$label cannot be empty';
            }
          }
          return null;
        },
      ),
    );
  }

  // Helper to check if a member section has any data, to make the name field required
  bool _isMemberSectionEmpty(String nameKey) {
    if (!nameKey.contains('name')) return false;

    final memberPrefix = nameKey.split('_name').first; // e.g., 'member_1'
    return (_controllers['${memberPrefix}_email']?.text.isEmpty ?? true) &&
        (_controllers['${memberPrefix}_number']?.text.isEmpty ?? true) &&
        (_controllers['${memberPrefix}_college']?.text.isEmpty ?? true);
  }
}
