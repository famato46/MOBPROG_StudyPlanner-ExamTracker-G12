import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../utils/app_colors.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Aggiunta variabile per controllare la Dark Mode
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        // Modifica 1: Titolo nel contenitore ovale
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart,
                size: 20,
                color: isDark ? Colors.white : AppColors.stats,
              ),
              const SizedBox(width: 8),
              Text(
                'Statistiche',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.stats,
                ),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Modifica 2: Rimossa la SectionHeader "Riepilogo Generale"
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StatRow('Corsi totali', provider.totalCourses.toString()),
                      _StatRow(
                          'Corsi superati', provider.passedCourses.toString()),
                      _StatRow('Esami programmati',
                          provider.upcomingExams.toString()),
                      _StatRow('Attività completate',
                          provider.completedTasksCount.toString()),
                      _StatRow('CFU ottenuti',
                          '${provider.earnedCfu}/${provider.totalCfu}'),
                      const Divider(),
                      _StatRow('Media ponderata',
                          provider.weightedAverage.toStringAsFixed(2)),
                      _StatRow('Voto laurea stimato',
                          provider.estimatedGraduationGrade.toStringAsFixed(1)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.stats,
            ),
          ),
        ],
      ),
    );
  }
}