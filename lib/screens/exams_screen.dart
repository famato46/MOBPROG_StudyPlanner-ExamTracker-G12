import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Capiamo se siamo in dark mode per adattare i colori testuali se serve
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        // Ecco il rettangolino grigiolino (che si adatta alla dark mode) intorno al titolo!
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            // In light mode è grigiolino chiaro, in dark mode è grigio scuro
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min, // Occupa solo lo spazio necessario
            children: [
              Icon(Icons.calendar_today, size: 20, color: isDark ? Colors.white : AppColors.exams),
              const SizedBox(width: 8),
              Text(
                'Esami e Scadenze',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.exams,
                ),
              ),
            ],
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // HO RIMOSSO LA SECTION HEADER DUPLICATA QUI!
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(Icons.calendar_today, size: 64, color: AppColors.exams),
                const SizedBox(height: 16),
                Text('Lista Esami - In arrivo',
                    style: TextStyle(color: isDark ? Colors.grey[400] : AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.exams,
        onPressed: () {},
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}