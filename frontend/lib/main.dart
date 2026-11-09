import 'package:flutter/material.dart';

import 'screens/bookings_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/members_screen.dart';
import 'screens/new_booking_screen.dart';
import 'screens/resources_screen.dart';

void main() {
  runApp(const CoWorkHubApp());
}

/// The root of the CoWorkHub desktop application.
class CoWorkHubApp extends StatelessWidget {
  const CoWorkHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CoWorkHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
      ),
      home: const HomeShell(),
    );
  }
}

/// The main window: a navigation rail on the left and the selected screen
/// on the right.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;

  // One entry per screen: the menu label, its icon and the screen itself.
  static const List<_NavItem> _items = [
    _NavItem('Dashboard', Icons.dashboard_outlined, DashboardScreen()),
    _NavItem('Resources', Icons.meeting_room_outlined, ResourcesScreen()),
    _NavItem('New Booking', Icons.add_circle_outline, NewBookingScreen()),
    _NavItem('Bookings', Icons.event_note_outlined, BookingsScreen()),
    _NavItem('Members', Icons.people_outline, MembersScreen()),
  ];

  @override
  Widget build(BuildContext context) {
    final item = _items[_selectedIndex];
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'CoWorkHub',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            destinations: [
              for (final navItem in _items)
                NavigationRailDestination(
                  icon: Icon(navItem.icon),
                  label: Text(navItem.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Scaffold(
              appBar: AppBar(title: Text(item.label)),
              body: item.screen,
            ),
          ),
        ],
      ),
    );
  }
}

/// A menu entry in the navigation rail.
class _NavItem {
  final String label;
  final IconData icon;
  final Widget screen;

  const _NavItem(this.label, this.icon, this.screen);
}