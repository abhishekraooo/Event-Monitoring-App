// lib/core/services/database_service.dart

import 'package:event_management_app/main.dart';

class DatabaseService {
  /// Fetches the role ('admin', 'core_coordinator', or 'coordinator') for the current user.
  Future<String> getCurrentUserRole() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final response = await supabase
          .from('coordinators')
          .select('role')
          .eq('id', userId)
          .single();
      return response['role'] ?? 'coordinator';
    } catch (e) {
      return 'coordinator';
    }
  }

  /// Fetches a single team and ALL its participants.
  Future<Map<String, dynamic>> getTeamById(int teamId) async {
    return await supabase
        .from('registrations')
        .select('*, participants(*)')
        .eq('id', teamId)
        .single();
  }

  Future<List<Map<String, dynamic>>> getTeamsWithLeads() async {
    return await supabase
        .from('registrations')
        .select('*, participants!inner(*)')
        .eq('participants.is_team_lead', true)
        .eq('status', 'active')
        .order('team_code', ascending: true); // Make sure this line is here
  }

  /// Updates a registration record in the database.
  Future<void> updateRegistration(
    int teamId,
    Map<String, dynamic> dataToUpdate,
  ) async {
    await supabase.from('registrations').update(dataToUpdate).eq('id', teamId);
  }

  /// Fetches a list of all coordinators (id and full_name).
  Future<List<Map<String, dynamic>>> getAllCoordinators() async {
    return await supabase.from('coordinators').select('id, full_name');
  }

  /// Assigns a coordinator to a list of teams in a single operation.
  Future<void> bulkAssignCoordinator(
    List<int> teamIds,
    String? coordinatorId,
  ) async {
    await supabase
        .from('registrations')
        .update({'assigned_coordinator_id': coordinatorId})
        .inFilter('id', teamIds);
  }

  /// Soft deletes a team by setting its status to 'inactive'.
  Future<void> deleteTeam(int teamId) async {
    await supabase
        .from('registrations')
        .update({'status': 'inactive'})
        .eq('id', teamId);
  }

  // MOVED: This method is now correctly inside the class.
  /// Updates a single participant's record in the 'participants' table.
  Future<void> updateParticipant(
    int participantId,
    Map<String, dynamic> dataToUpdate,
  ) async {
    await supabase
        .from('participants')
        .update(dataToUpdate)
        .eq('id', participantId);
  }

  Future<List<Map<String, dynamic>>> getParticipantStats() async {
    return await supabase
        .from('participants')
        .select('*, registrations(*)')
        .order('id');
  }

  Future<Map<String, dynamic>?> getTeamByCode(String teamCode) async {
    try {
      // Add 'team_code' to the select query
      return await supabase
          .from('registrations')
          .select('id, team_name, team_code')
          .eq('team_code', teamCode)
          .single();
    } catch (e) {
      return null;
    }
  }

  /// Fetches all participants for a single team.
  Future<List<Map<String, dynamic>>> getParticipantsForTeam(int teamId) async {
    return await supabase
        .from('participants')
        .select()
        .eq('team_id', teamId)
        .order('is_team_lead', ascending: false); // Show lead first
  }

  /// Fetches the calculated attendance status for all teams from the view.
  Future<List<Map<String, dynamic>>> getTeamAttendanceStatus() async {
    // We select from the 'view' as if it were a normal table.
    return await supabase.from('team_attendance_status').select();
  }

  /// Creates a new team and its participants using a database function.
  Future<void> createNewTeam(Map<String, dynamic> teamData) async {
    await supabase.rpc('create_new_team', params: {'team_data': teamData});
  }

  /// Updates the status for a list of participants using the database function.
  Future<void> bulkUpdateParticipantStatus(
    List<Map<String, dynamic>> updates,
  ) async {
    await supabase.rpc(
      'bulk_update_participant_status',
      params: {'updates': updates},
    );
  }

  /// Adds a new participant to a team.
  Future<void> addParticipant(Map<String, dynamic> participantData) async {
    await supabase.from('participants').insert(participantData);
  }

  /// Deletes a participant from a team.
  Future<void> deleteParticipant(int participantId) async {
    await supabase.from('participants').delete().eq('id', participantId);
  }
}
