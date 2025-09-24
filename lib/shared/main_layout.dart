// lib/features/coordinator/shared/main_layout.dart

import 'package:event_management_app/features/coordinator/dashboard/dashboard_screen.dart';
import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  // This list holds the different screens for your app.
  // We'll add more screens here as we build them.
  static const List<Widget> _screens = <Widget>[
    DashboardScreen(), // Index 0
    // Placeholder for Teams Screen
    Center(child: Text('All Registrations Screen (coming soon)')), // Index 1
    // Placeholder for Admin Screen
    Center(child: Text('Admin Panel (coming soon)')), // Index 2
  ];

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder helps us decide which layout to show based on screen width
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 640) {
          // WIDE SCREEN LAYOUT (Desktop)
          return Scaffold(
            body: Row(
              children: [
                NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  labelType: NavigationRailLabelType.all,
                  extended: false,
                  destinations: const <NavigationRailDestination>[
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard),
                      label: Text('Dashboard'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.list_alt_outlined),
                      selectedIcon: Icon(Icons.list_alt),
                      label: Text('Teams'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.admin_panel_settings_outlined),
                      selectedIcon: Icon(Icons.admin_panel_settings),
                      label: Text('Admin'),
                    ),
                  ],
                ),
                const VerticalDivider(thickness: 1, width: 1),
                // Main content area
                Expanded(child: _screens.elementAt(_selectedIndex)),
              ],
            ),
          );
        } else {
          // NARROW SCREEN LAYOUT (Mobile)
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
                  ListTile(
                    leading: const Icon(Icons.dashboard),
                    title: const Text('Dashboard'),
                    selected: _selectedIndex == 0,
                    onTap: () {
                      setState(() => _selectedIndex = 0);
                      Navigator.pop(context); // Close the drawer
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.list_alt),
                    title: const Text('Teams'),
                    selected: _selectedIndex == 1,
                    onTap: () {
                      setState(() => _selectedIndex = 1);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.admin_panel_settings),
                    title: const Text('Admin'),
                    selected: _selectedIndex == 2,
                    onTap: () {
                      setState(() => _selectedIndex = 2);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            body: _screens.elementAt(_selectedIndex),
          );
        }
      },
    );
  }
}
