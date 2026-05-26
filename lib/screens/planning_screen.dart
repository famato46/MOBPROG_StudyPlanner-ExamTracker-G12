import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../widgets/section_header.dart';

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pianificazione'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader(
              titolo: 'Pianificazione', icona: Icons.event_note),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                Icon(Icons.event_note, size: 64, color: AppColors.planning),
                const SizedBox(height: 16),
                Text('Calendario e Sessioni - In arrivo',
                    style: TextStyle(color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}