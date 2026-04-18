import 'package:flutter/material.dart';

import '../../../appointments/presentation/screens/appointments_screen.dart';
import '../../../diet_plans/presentation/screens/diet_plan_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import 'home_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _pages = [
    HomeScreen(onNavigate: _onNavigate),
    const AppointmentsScreen(),
    const DietPlanScreen(),
    const ProfileScreen(),
  ];

  void _onNavigate(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavigate,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Ana Sayfa'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note_rounded), label: 'Takvim'),
          BottomNavigationBarItem(icon: Icon(Icons.dinner_dining_rounded), label: 'Diyet'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profil'),
        ],
      ),
    );
  }
}
