import 'package:flutter/material.dart';
import 'package:meka_app/Admin/register_mechanic_screen.dart';

import 'view_mechanics_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    Center(child: Text('Dashboard Home')),
    MechanicRegistrationScreen(),
    ViewMechanicsScreen(),
    Center(child: Text('Manage Users')),
    Center(child: Text('Service Requests')),
    Center(child: Text('Reports')),
    Center(child: Text('Settings')),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Register Mechanic',
    'View Mechanics',
    'Manage Users',
    'Service Requests',
    'Reports',
    'Settings',
  ];

  void _onSelect(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // Close drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('MechaConnect Admin',
                  style: TextStyle(color: Colors.white, fontSize: 20)),
            ),
            for (int i = 0; i < _titles.length; i++)
              ListTile(
                title: Text(_titles[i]),
                leading: Icon(Icons.circle),
                selected: _selectedIndex == i,
                onTap: () => _onSelect(i),
              ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
