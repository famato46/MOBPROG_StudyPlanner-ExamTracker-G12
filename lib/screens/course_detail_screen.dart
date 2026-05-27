import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../providers/planner_provider.dart';
import '../utils/app_colors.dart';
import 'course_form_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  String _formatStato(String stato) {
    switch (stato) {
      case 'da_iniziare': return 'Da iniziare';
      case 'in_corso': return 'In corso';
      case 'da_ripassare': return 'Da ripassare';
      case 'completato': return 'Completato';
      case 'superato': return 'Superato';
      default: return stato;
    }
  }

  // Riquadrino titolo AppBar — stesso pattern delle altre schermate
  Widget _buildTitleBadge(BuildContext context, String nome) {
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
          Icon(Icons.book,
              size: 20,
              color: isDark ? Colors.white : AppColors.courses),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              nome,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.courses,
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
        final updatedCourse =
            provider.getCourseById(course.id) ?? course;
        final exams = provider.getExamsByCourse(updatedCourse.id);
        final tasks = provider.getTasksByCourse(updatedCourse.id);

        return Scaffold(
          // FIX: rimosso backgroundColor fisso — ora segue il tema
          appBar: AppBar(
            // FIX: rimossi backgroundColor e foregroundColor fissi
            title: _buildTitleBadge(context, updatedCourse.nome),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CourseFormScreen(
                        courseToEdit: updatedCourse),
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete, color: AppColors.danger),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('Elimina corso'),
                      content: const Text(
                          'Eliminare questo corso? Saranno eliminati anche esami e attività collegate.'),
                      actions: [
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('Annulla')),
                        TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: Text('Elimina',
                                style: TextStyle(
                                    color: AppColors.danger))),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await provider.deleteCourse(updatedCourse.id);
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // FIX: rimosso color: AppColors.surface fisso dalla Card
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow('Docente', updatedCourse.docente),
                      _InfoRow('CFU', updatedCourse.cfu.toString()),
                      _InfoRow('Semestre', updatedCourse.semestre),
                      _InfoRow('Stato', _formatStato(updatedCourse.stato)),
                      if (updatedCourse.votoOttenuto != null)
                        _InfoRow('Voto ottenuto',
                            '${updatedCourse.votoOttenuto}/30'),
                      if (updatedCourse.votoDesiderato != null)
                        _InfoRow('Voto mirato',
                            '${updatedCourse.votoDesiderato}/30'),
                      if (updatedCourse.note != null &&
                          updatedCourse.note!.isNotEmpty)
                        _InfoRow('Note', updatedCourse.note!),
                      if (updatedCourse.materialeAssociato != null &&
                          updatedCourse.materialeAssociato!.isNotEmpty)
                        _InfoRow('Materiale',
                            updatedCourse.materialeAssociato!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // FIX: rimosso color: AppColors.coursesDark fisso — usa tema
              Text('Esami (${exams.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (exams.isEmpty)
                Text('Nessun esame collegato.',
                    style: TextStyle(color: AppColors.textMuted))
              else
                ...exams.map((e) => Card(
                      // FIX: rimosso color fisso
                      child: ListTile(
                        leading:
                            Icon(Icons.event, color: AppColors.exams),
                        title: Text(e.titolo),
                        subtitle: Text(
                            '${e.tipologia} · ${e.data.day}/${e.data.month}/${e.data.year}'),
                        trailing: Text(e.stato,
                            style: TextStyle(
                                color: e.isCompletato
                                    ? AppColors.success
                                    : AppColors.warning)),
                      ),
                    )),
              const SizedBox(height: 20),

              // FIX: rimosso color: AppColors.coursesDark fisso
              Text('Attività (${tasks.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                Text('Nessuna attività collegata.',
                    style: TextStyle(color: AppColors.textMuted))
              else
                ...tasks.map((t) => Card(
                      // FIX: rimosso color fisso
                      child: CheckboxListTile(
                        title: Text(
                          t.titolo,
                          style: TextStyle(
                            decoration: t.completata
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(t.priorita),
                        activeColor: AppColors.courses,
                        value: t.completata,
                        onChanged: (_) =>
                            provider.toggleTaskCompletion(t.id),
                      ),
                    )),
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
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
          ),
          Expanded(
              child:
                  Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}