import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../utils/app_colors.dart';
import '../widgets/section_header.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiche'),
      ),
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(
                  titolo: 'Riepilogo Generale', icona: Icons.bar_chart),
              const SizedBox(height: 12),
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