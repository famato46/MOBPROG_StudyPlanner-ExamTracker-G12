import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';
import 'courses_screen.dart';
import 'exams_screen.dart';
import 'planning_screen.dart';
import 'stats_screen.dart';

/// MainScreen — Container con BottomNavigationBar stile Apple.
///
/// Pattern del prof: `_currentIndex` + `setState` per cambiare tab,
/// le 5 schermate sono pre-istanziate in un array così il loro stato
/// non viene distrutto cambiando tab.
///
/// Stile: tutte le icone selezionate diventano blu iOS standard
/// (#007AFF), non più colore-per-sezione, per coerenza con iOS.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  /// Cambia la tab attiva. Passata in giù alla HomeScreen come
  /// VoidCallback (pattern "evento dal basso verso l'alto" del prof)
  /// così le card della dashboard possono navigare alle altre sezioni.
  void _goToTab(int index) => setState(() => _currentIndex = index);

  // Le schermate sono costruite in build (non più const) perché la
  // HomeScreen riceve la callback _goToTab. Restano comunque istanziate
  // una sola volta dentro l'IndexedStack, che ne preserva lo stato.
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final screens = <Widget>[
      HomeScreen(onNavigateToTab: _goToTab),
      const CoursesScreen(),
      const ExamsScreen(),
      const PlanningScreen(),
      const StatsScreen(),
    ];

    return Scaffold(
      // IndexedStack mantiene tutte le tab in memoria → no rebuild
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1C1C1E)
              : AppColors.surface,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.border,
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            // Stile Apple: blu iOS standard quando selezionato
            selectedItemColor: AppColors.iosBlue,
            unselectedItemColor: isDark
                ? Colors.grey[500]
                : AppColors.textMuted,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.1,
            ),
            iconSize: 24,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.book_outlined),
                activeIcon: Icon(Icons.book_rounded),
                label: 'Corsi',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today_rounded),
                label: 'Esami',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.event_note_outlined),
                activeIcon: Icon(Icons.event_note_rounded),
                label: 'Pianifica',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_outlined),
                activeIcon: Icon(Icons.bar_chart_rounded),
                label: 'Stats',
              ),
            ],
          ),
        ),
      ),
    );
  }
}