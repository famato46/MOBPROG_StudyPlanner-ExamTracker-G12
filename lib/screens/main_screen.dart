import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
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

  final List<Widget> _screens = const [
    HomeScreen(),
    CoursesScreen(),
    ExamsScreen(),
    PlanningScreen(),
    StatsScreen(),
  ];

  final List<Color> _sectionColors = const [
    AppColors.home,
    AppColors.courses,
    AppColors.exams,
    AppColors.planning,
    AppColors.stats,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Theme.of(context).colorScheme.surface, 
        selectedItemColor: _sectionColors[_currentIndex],
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark 
            ? Colors.grey[500] // grigio chiaro per la dark mode
            : AppColors.textMuted, // grigio normale per la light mode
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: 'Corsi'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Esami'),
          BottomNavigationBarItem(icon: Icon(Icons.event_note), label: 'Pianifica'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
        ],
      ),
    );
  }
}