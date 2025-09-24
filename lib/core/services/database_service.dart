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
}
