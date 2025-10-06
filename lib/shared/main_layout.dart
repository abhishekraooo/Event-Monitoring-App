// lib/features/coordinator/shared/main_layout.dart

import 'package:event_management_app/core/utils/snackbar_utils.dart';
import 'package:event_management_app/main.dart';
import 'package:flutter/material.dart';
import 'package:event_management_app/features/coordinator/attendance/attendance_dashboard_screen.dart';
import 'package:event_management_app/features/coordinator/food/food_count_dashboard_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:event_management_app/features/coordinator/teams/teams_screen.dart';
import 'package:event_management_app/features/coordinator/dashboard/dashboard_screen.dart';
import 'package:event_management_app/features/coordinator/admin/admin_screen.dart';
import 'package:event_management_app/core/services/database_service.dart';

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
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (_userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // --- Dynamically build the list of navigation items based on role ---
    final List<Map<String, dynamic>> navItems = [
      {
        'label': 'Dashboard',
        'icon': Icons.dashboard_outlined,
        'selectedIcon': Icons.dashboard,
        'screen': const DashboardScreen(),
      },
      {
        'label': 'Teams',
        'icon': Icons.list_alt_outlined,
        'selectedIcon': Icons.list_alt,
        'screen': const TeamsScreen(),
      },
    ];

    if (_userRole != 'viewer') {
      navItems.add({
        'label': 'Attendance',
        'icon': Icons.person_search_outlined,
        'selectedIcon': Icons.person_search,
        'screen': const AttendanceDashboardScreen(),
      });
      navItems.add({
        'label': 'Food Count',
        'icon': Icons.restaurant_outlined,
        'selectedIcon': Icons.restaurant,
        'screen': const FoodCountDashboardScreen(),
      });
    }

    if (_userRole == 'admin') {
      navItems.add({
        'label': 'Admin',
        'icon': Icons.admin_panel_settings_outlined,
        'selectedIcon': Icons.admin_panel_settings,
        'screen': const AdminScreen(),
      });
    }
    // --- END of dynamic list building ---

    // Generate the UI components from the dynamic list
    final screens = navItems.map<Widget>((item) => item['screen']).toList();
    final navRailDestinations = navItems
        .map<NavigationRailDestination>(
          (item) => NavigationRailDestination(
            icon: Icon(item['icon']),
            selectedIcon: Icon(item['selectedIcon']),
            label: Text(item['label']),
          ),
        )
        .toList();
    final drawerItems = navItems.asMap().entries.map<Widget>((entry) {
      final index = entry.key;
      final item = entry.value;
      return ListTile(
        leading: Icon(item['icon']),
        title: Text(item['label']),
        selected: _selectedIndex == index,
        onTap: () => _onSelectItem(index),
      );
    }).toList();

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
