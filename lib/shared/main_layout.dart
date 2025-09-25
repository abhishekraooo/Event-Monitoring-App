// lib/features/coordinator/shared/main_layout.dart

import 'package:event_management_app/core/services/database_service.dart';
import 'package:event_management_app/features/coordinator/admin/admin_screen.dart';
import 'package:event_management_app/features/coordinator/dashboard/dashboard_screen.dart';
import 'package:event_management_app/features/coordinator/teams/teams_screen.dart';
import 'package:event_management_app/main.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});
  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;
  String? _userRole; // To store the user's role
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

  @override
  Widget build(BuildContext context) {
    // Dynamically build the screens and nav destinations based on role
    final List<Widget> screens = [
      const DashboardScreen(),
      const TeamsScreen(),
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
      if (_userRole == 'admin')
        ListTile(
          leading: const Icon(Icons.admin_panel_settings),
          title: const Text('Admin'),
          selected: _selectedIndex == 2,
          onTap: () => _onSelectItem(2),
        ),
    ];

    if (_userRole == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 640) {
          return Scaffold(
            body: Row(
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
                          onPressed: () => supabase.auth.signOut(),
                        ),
                      ),
                    ),
                  ),
                ),
                const VerticalDivider(thickness: 1, width: 1),
                Expanded(child: screens[_selectedIndex]),
              ],
            ),
          );
        } else {
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
                      supabase.auth.signOut();
                    },
                  ),
                ],
              ),
            ),
            body: screens[_selectedIndex],
          );
        }
      },
    );
  }

  void _onSelectItem(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // Close drawer
  }
}
