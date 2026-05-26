import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/section_header.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Esami e Scadenze'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
              titolo: 'Esami e Scadenze', icona: Icons.calendar_today),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(Icons.calendar_today, size: 64, color: AppColors.exams),
                const SizedBox(height: 16),
                Text('Lista Esami - In arrivo',
                    style: TextStyle(color: AppColors.textMuted)),
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