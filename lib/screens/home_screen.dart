import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../providers/theme_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home,
                  size: 20,
                  color: isDark ? Colors.white : const Color(0xFF7F77DD)),
              const SizedBox(width: 8),
              Text(
                'Dashboard',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF7F77DD),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return IconButton(
                icon: Icon(
                  themeProvider.isDarkMode
                      ? Icons.light_mode
                      : Icons.dark_mode,
                ),
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
        ],
      ),
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (provider.suggerimentiAutomatici.isNotEmpty) ...[
                const SectionHeader(
                    titolo: 'Consigliati per te',
                    icona: Icons.lightbulb_outline),
                const SizedBox(height: 12),
                ...provider.suggerimentiAutomatici.map((suggerimento) => Card(
                      child: ListTile(
                        leading: const Icon(Icons.lightbulb_outline,
                            color: Color(0xFF7F77DD)),
                        title: Text(suggerimento),
                      ),
                    )),
                const SizedBox(height: 20),
              ],
              const SectionHeader(
                  titolo: 'Panoramica', icona: Icons.dashboard_outlined),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Corsi',
                      value: provider.activeCourses.toString(),
                      icon: Icons.book,
                      color: const Color(0xFF1D9E75),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'Esami',
                      value: provider.upcomingExams.toString(),
                      icon: Icons.event,
                      color: const Color(0xFFD4537E),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Attività',
                      value: provider.pendingTasks.toString(),
                      icon: Icons.check_circle_outline,
                      color: const Color(0xFFEF9F27),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      title: 'CFU',
                      value:
                          '${provider.earnedCfu}/${provider.totalCfu}',
                      icon: Icons.school,
                      color: const Color(0xFF378ADD),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String titolo;
  final IconData icona;

  const SectionHeader({
    super.key,
    required this.titolo,
    required this.icona,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFE8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icona, size: 20, color: const Color(0xFF444441)),
          const SizedBox(width: 8),
          Text(
            titolo,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF444441),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                // FIX: withOpacity → withValues
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 12, color: Color(0xFF888780)),
            ),
          ],
        ),
      ),
    );
  }
}