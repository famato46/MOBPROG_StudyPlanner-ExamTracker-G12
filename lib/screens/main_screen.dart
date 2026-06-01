import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'courses_screen.dart';
import 'exams_screen.dart';
import 'planning_screen.dart';
import 'stats_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _goToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {

    final screens = <Widget>[
      HomeScreen(onNavigateToTab: _goToTab),
      const CoursesScreen(),
      const ExamsScreen(),
      const PlanningScreen(),
      const StatsScreen(),
    ];

    return Scaffold(
      // IndexedStack mantiene tutte le tab in memoria
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      // NavigationBar
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: Duration.zero,
        destinations: [
          _dest(Icons.home_outlined, Icons.home_rounded, 'Home'),
          _dest(Icons.book_outlined, Icons.book_rounded, 'Corsi'),
          _dest(Icons.calendar_today_outlined,
              Icons.calendar_today_rounded, 'Esami'),
          _dest(Icons.event_note_outlined,
              Icons.event_note_rounded, 'Pianifica'),
          _dest(Icons.bar_chart_outlined,
              Icons.bar_chart_rounded, 'Stats'),
        ],
      ),
    );
  }

  NavigationDestination _dest(
      IconData outline, IconData filled, String label) {
    return NavigationDestination(
      icon: Icon(outline),
      selectedIcon: Icon(filled, color: Theme.of(context).colorScheme.primary),
      label: label,
    );
  }
}