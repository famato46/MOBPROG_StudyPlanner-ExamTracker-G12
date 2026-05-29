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
      // NavigationBar (Material 3) — nessun ripple grigio Android,
      // nessuna transizione aggiunta.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) =>
            setState(() => _currentIndex = index),
        backgroundColor: isDark
            ? const Color(0xFF1C1C1E)
            : AppColors.surface,
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
      selectedIcon: Icon(filled, color: AppColors.iosBlue),
      label: label,
    );
  }
}