// lib/core/services/database_service.dart

import 'package:event_management_app/main.dart';

class DatabaseService {
  /// Fetches the role ('admin' or 'coordinator') for the current user.
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
      // Default to the least privileged role on error
      return 'coordinator';
    }
  }

  /// Fetches all data for a single team by its primary key ID.
  Future<Map<String, dynamic>> getTeamById(int teamId) async {
    return await supabase
        .from('registrations')
        .select()
        .eq('id', teamId)
        .single();
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
  /// Pass null for coordinatorId to unassign.
  Future<void> bulkAssignCoordinator(
    List<int> teamIds,
    String? coordinatorId,
  ) async {
    await supabase
        .from('registrations')
        .update({'assigned_coordinator_id': coordinatorId})
        .inFilter('id', teamIds);
  }
}
