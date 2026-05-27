import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/exam.dart';
import '../providers/planner_provider.dart';
import '../utils/app_colors.dart';
import 'exam_form_screen.dart';

class ExamDetailScreen extends StatelessWidget {
  final Exam exam;
  const ExamDetailScreen({super.key, required this.exam});

  Widget _buildTitleBadge(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.calendar_today,
              size: 20, color: isDark ? Colors.white : AppColors.exams),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              exam.titolo,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.exams,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerProvider>(
      builder: (context, provider, child) {
        final updatedExam = provider.getExamById(exam.id) ?? exam;
        final corso = provider.getCourseById(updatedExam.courseId);

        final colore = updatedExam.isCompletato
            ? AppColors.success
            : updatedExam.isImminente
                ? AppColors.danger
                : updatedExam.isPassato
                    ? AppColors.textMuted
                    : AppColors.exams;

        return Scaffold(
          appBar: AppBar(
            title: _buildTitleBadge(context),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExamFormScreen(exam: updatedExam),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: AppColors.danger),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Elimina esame'),
                      content: Text('Eliminare "${updatedExam.titolo}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Annulla'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('Elimina',
                              style: TextStyle(color: AppColors.danger)),
                        ),
                      ],
                    ),
                  );
                  if (!context.mounted) return;
                  if (confirm == true) {
                    await provider.deleteExam(updatedExam.id);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Card info principali
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow('Corso', corso?.nome ?? 'Corso non trovato'),
                      _InfoRow('Data',
                          '${updatedExam.data.day}/${updatedExam.data.month}/${updatedExam.data.year}'),
                      _InfoRow('Tipologia', updatedExam.tipologia),
                      _InfoRow('Priorità', updatedExam.priorita),
                      _InfoRow('Stato', updatedExam.stato),
                      if (updatedExam.voto != null)
                        _InfoRow('Voto', '${updatedExam.voto}/30'),
                      if (updatedExam.note != null &&
                          updatedExam.note!.isNotEmpty)
                        _InfoRow('Note', updatedExam.note!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Badge stato visivo
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: colore.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: colore),
                  ),
                  child: Text(
                    updatedExam.isCompletato
                        ? '✓ Completato'
                        : updatedExam.isImminente
                            ? '⚠ Imminente — meno di 7 giorni!'
                            : updatedExam.isPassato
                                ? 'Passato'
                                : 'Programmato',
                    style: TextStyle(
                      color: colore,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sessioni di studio collegate
              Text(
                'Sessioni di studio collegate',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final sessioni = provider.studySessions
                      .where((s) => s.examId == updatedExam.id)
                      .toList();

                  if (sessioni.isEmpty) {
                    return Text(
                      'Nessuna sessione collegata.',
                      style: TextStyle(color: AppColors.textMuted),
                    );
                  }

                  return Column(
                    children: sessioni
                        .map((s) => Card(
                              child: ListTile(
                                leading: Icon(Icons.timer,
                                    color: AppColors.planning),
                                title: Text(s.titolo),
                                subtitle: Text(
                                    '${s.durataPianificata} min · ${s.tipo}'),
                                trailing: s.completata
                                    ? Icon(Icons.check_circle,
                                        color: AppColors.success)
                                    : null,
                              ),
                            ))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}