import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../providers/planner_provider.dart';
import '../utils/app_colors.dart';
import 'course_form_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Consumer<PlannerProvider>(
      builder: (context, provider, child) {
        final updatedCourse = provider.getCourseById(course.id) ?? course;
        final exams = provider.getExamsByCourse(updatedCourse.id);
        final tasks = provider.getTasksByCourse(updatedCourse.id);

        return Scaffold(
          backgroundColor: AppColors.coursesLight,
          appBar: AppBar(
            title: Text(updatedCourse.nome),
            backgroundColor: AppColors.coursesLight,
            foregroundColor: AppColors.coursesDark,
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CourseFormScreen(course: updatedCourse),
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
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Annulla')),
                        TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text('Elimina',
                                style: TextStyle(color: AppColors.danger))),
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
              Card(
                color: AppColors.surface,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow('Docente', updatedCourse.docente),
                      _InfoRow('CFU', updatedCourse.cfu.toString()),
                      _InfoRow('Semestre', updatedCourse.semestre),
                      _InfoRow('Stato', updatedCourse.stato),
                      if (updatedCourse.votoOttenuto != null)
                        _InfoRow('Voto', '${updatedCourse.votoOttenuto}/30'),
                      if (updatedCourse.votoDesiderato != null)
                        _InfoRow('Voto desiderato',
                            '${updatedCourse.votoDesiderato}/30'),
                      if (updatedCourse.note != null &&
                          updatedCourse.note!.isNotEmpty)
                        _InfoRow('Note', updatedCourse.note!),
                      if (updatedCourse.materialeAssociato != null &&
                          updatedCourse.materialeAssociato!.isNotEmpty)
                        _InfoRow(
                            'Materiale', updatedCourse.materialeAssociato!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Esami (${exams.length})',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.coursesDark)),
              const SizedBox(height: 8),
              if (exams.isEmpty)
                Text('Nessun esame collegato.',
                    style: TextStyle(color: AppColors.textMuted))
              else
                ...exams.map((e) => Card(
                      color: AppColors.surface,
                      child: ListTile(
                        leading: Icon(Icons.event, color: AppColors.exams),
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
              const SizedBox(height: 16),
              Text('Attività (${tasks.length})',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.coursesDark)),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                Text('Nessuna attività collegata.',
                    style: TextStyle(color: AppColors.textMuted))
              else
                ...tasks.map((t) => Card(
                      color: AppColors.surface,
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
      padding: const EdgeInsets.symmetric(vertical: 4),
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
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}