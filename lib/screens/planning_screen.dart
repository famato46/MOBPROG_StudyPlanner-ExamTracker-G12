import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

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
              Icon(
                Icons.event_note, 
                size: 20, 
                color: isDark ? Colors.white : AppColors.planning,
              ),
              const SizedBox(width: 8),
              Text(
                'Pianificazione',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.planning,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Il blocco SectionHeader "Pianificazione" è stato rimosso da qui
          Center(
            child: Column(
              children: [
                Icon(Icons.event_note, size: 64, color: AppColors.planning),
                const SizedBox(height: 16),
                Text(
                  'Calendario e Sessioni - In arrivo',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}