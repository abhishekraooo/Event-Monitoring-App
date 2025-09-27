// lib/features/coordinator/shared/main_layout.dart

import 'package:event_management_app/core/utils/snackbar_utils.dart';
import 'package:flutter/material.dart';
import 'package:event_management_app/features/coordinator/admin/admin_screen.dart';
import 'package:event_management_app/features/coordinator/attendance/attendance_dashboard_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:event_management_app/features/coordinator/dashboard/dashboard_screen.dart';
import 'package:event_management_app/features/coordinator/teams/teams_screen.dart';
import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/main.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  String? _userRole;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    final role = await _dbService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        _userRole = role;
      });
    }
  }

  Future<void> _showSignOutConfirmation() async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
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
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await supabase.auth.signOut();
    }
  }

  void _onSelectItem(int index) {
    // This logic prevents out-of-bounds errors if the admin tab isn't visible
    final adminIndex = 3;
    final maxIndex = _userRole == 'admin' ? 3 : 2;
    if (index > maxIndex) return;

    setState(() => _selectedIndex = index);
    Navigator.pop(context); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> screens = [
      const DashboardScreen(),
      const TeamsScreen(),
      const AttendanceDashboardScreen(),
      if (_userRole == 'admin') const AdminScreen(),
    ];

    final List<NavigationRailDestination> navRailDestinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        selectedIcon: Icon(Icons.dashboard),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.list_alt_outlined),
        selectedIcon: Icon(Icons.list_alt),
        label: Text('Teams'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.person_search_outlined),
        selectedIcon: Icon(Icons.person_search),
        label: Text('Attendance'),
      ),
      if (_userRole == 'admin')
        const NavigationRailDestination(
          icon: Icon(Icons.admin_panel_settings_outlined),
          selectedIcon: Icon(Icons.admin_panel_settings),
          label: Text('Admin'),
        ),
    ];

    final List<Widget> drawerItems = [
      ListTile(
        leading: const Icon(Icons.dashboard),
        title: const Text('Dashboard'),
        selected: _selectedIndex == 0,
        onTap: () => _onSelectItem(0),
      ),
      ListTile(
        leading: const Icon(Icons.list_alt),
        title: const Text('Teams'),
        selected: _selectedIndex == 1,
        onTap: () => _onSelectItem(1),
      ),
      ListTile(
        leading: const Icon(Icons.person_search),
        title: const Text('Attendance'),
        selected: _selectedIndex == 2,
        onTap: () => _onSelectItem(2),
      ),
      if (_userRole == 'admin')
        ListTile(
          leading: const Icon(Icons.admin_panel_settings),
          title: const Text('Admin'),
          selected: _selectedIndex == 3,
          onTap: () => _onSelectItem(3),
        ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 640) {
          // WIDE SCREEN LAYOUT
          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      NavigationRail(
                        selectedIndex: _selectedIndex,
                        onDestinationSelected: (int index) =>
                            setState(() => _selectedIndex = index),
                        labelType: NavigationRailLabelType.all,
                        destinations: navRailDestinations,
                        trailing: Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: IconButton(
                                icon: const Icon(Icons.logout),
                                tooltip: 'Sign Out',
                                onPressed: _showSignOutConfirmation,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const VerticalDivider(thickness: 1, width: 1),
                      Expanded(child: screens[_selectedIndex]),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const _CreditsFooter(),
              ],
            ),
          );
        } else {
          // NARROW SCREEN LAYOUT
          return Scaffold(
            appBar: AppBar(title: const Text('Ideathon Monitor')),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: Colors.black),
                    child: Text(
                      'Menu',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  ...drawerItems,
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Sign Out'),
                    onTap: () {
                      Navigator.pop(context);
                      _showSignOutConfirmation();
                    },
                  ),
                ],
              ),
            ),
            body: screens[_selectedIndex],
            bottomNavigationBar: const _CreditsFooter(),
          );
        }
      },
    );
  }
}

class _CreditsFooter extends StatelessWidget {
  const _CreditsFooter();

  Future<void> _launchPhone(BuildContext context) async {
    final Uri phoneNumber = Uri.parse('tel:+919606248727');
    if (await canLaunchUrl(phoneNumber)) {
      await launchUrl(phoneNumber);
    } else {
      showFeedbackSnackbar(
        context,
        'Could not open phone dialer.',
        type: FeedbackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _launchPhone(context),
      child: Container(
        color: Theme.of(context).cardTheme.color,
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.call, size: 14, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'Managed by Team Tryanuka',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
