import 'package:flutter/material.dart';
import 'package:meka_app/Admin/register_mechanic_screen.dart';
import 'package:meka_app/Admin/view_mechanics_screen.dart'; // Import View Mechanics page

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // Pages corresponding to the selected index
  final List<Widget> _pages = const [
    Center(
        child:
            Text('Welcome to the Dashboard', style: TextStyle(fontSize: 24))),
    MechanicRegistrationScreen(),
    ViewMechanicsScreen(),
    Center(child: Text('Manage Users')),
    Center(child: Text('Service Requests')),
    Center(child: Text('Reports')),
    Center(child: Text('Settings')),
  ];

  // Titles for each section
  final List<String> _titles = [
    'Dashboard',
    'Register Mechanic',
    'View Mechanics',
    'Manage Users',
    'Service Requests',
    'Reports',
    'Settings',
  ];

  // Icons for each section
  final List<IconData> _icons = [
    Icons.dashboard,
    Icons.person_add,
    Icons.visibility,
    Icons.group,
    Icons.list_alt,
    Icons.analytics,
    Icons.settings,
  ];

  // Handle drawer navigation
  void _onSelect(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context); // Close drawer after selection
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]), // Update the app bar title
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('MechaConnect Admin',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            // Drawer items with corresponding titles and icons
            for (int i = 0; i < _titles.length; i++)
              ListTile(
                title: Text(_titles[i]),
                leading: Icon(_icons[i]),
                selected: _selectedIndex == i,
                onTap: () => _onSelect(i),
              ),
          ],
        ),
      ),
      body: _pages[_selectedIndex], // Display the selected page
    );
  }
}
