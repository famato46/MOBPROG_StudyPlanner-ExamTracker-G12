import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../models/task.dart';
import '../providers/planner_provider.dart';
import '../utils/app_colors.dart';
import 'course_form_screen.dart';
import 'task_form_screen.dart';
import 'exam_detail_screen.dart';

class CourseDetailScreen extends StatelessWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  String _formatStato(String stato) {
    switch (stato) {
      case 'da_iniziare':
        return 'Da iniziare';
      case 'in_corso':
        return 'In corso';
      case 'completato':
        return 'Frequentato';
      case 'superato':
        return 'Superato';
      default:
        return stato;
    }
  }

  String _formatTipologia(String t) {
    switch (t) {
      case 'esame':
        return 'Esame';
      case 'appello':
        return 'Appello';
      case 'consegna':
        return 'Consegna';
      case 'progetto':
        return 'Progetto';
      default:
        return t;
    }
  }

  // Converte un voto numerico interno in stringa per gestire 30L
  String _formatVoto(int? voto) {
    if (voto == null) return '-';
    if (voto >= 31) return '30L';
    return voto.toString();
  }

  String _shortSemestre(String s) {
    return s
        .replaceAll('Primo semestre', '1° sem')
        .replaceAll('Secondo semestre', '2° sem')
        .replaceAll('20', '');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF000000) : AppColors.background;

    return Consumer<PlannerProvider>(
      builder: (context, provider, child) {
        final updatedCourse =
            provider.getCourseById(course.id) ?? course;
        final exams = provider.getExamsByCourse(updatedCourse.id);
        final tasks = provider.getTasksByCourse(updatedCourse.id);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: const Icon(Icons.chevron_left_rounded, size: 32),
              color: AppColors.iosBlue,
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              updatedCourse.nome,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 22),
                color: AppColors.iosBlue,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        CourseFormScreen(courseToEdit: updatedCourse),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 22),
                color: AppColors.danger,
                onPressed: () =>
                    _handleDelete(context, provider, updatedCourse),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HeroCard(
                course: updatedCourse,
                statoLabel: _formatStato(updatedCourse.stato),
                votoOttenuto: _formatVoto(updatedCourse.votoOttenuto),
                votoDesiderato: _formatVoto(updatedCourse.votoDesiderato),
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              //MINI-GRID INFO
              Row(
                children: [
                  Expanded(
                    child: _MiniInfoCard(
                      label: 'SEMESTRE',
                      value: _shortSemestre(updatedCourse.semestre),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniInfoCard(
                      label: 'VOTO',
                      value: updatedCourse.votoOttenuto != null
                          ? '${_formatVoto(updatedCourse.votoOttenuto)} / 30'
                          : '—',
                      valueColor: updatedCourse.votoOttenuto != null
                          ? AppColors.success
                          : null,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              // NOTE
              if ((updatedCourse.note?.isNotEmpty ?? false) ||
                  (updatedCourse.materialeAssociato?.isNotEmpty ??
                      false)) ...[
                const SizedBox(height: 14),
                _NoteCard(
                  note: updatedCourse.note,
                  materiale: updatedCourse.materialeAssociato,
                  isDark: isDark,
                ),
              ],

              // SEZIONE ESAMI 
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'Esami',
                count: exams.length,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              if (exams.isEmpty)
                _EmptyCard(text: 'Nessun esame collegato', isDark: isDark)
              else
                _ItemsContainer(
                  isDark: isDark,
                  children: exams
                      .map((e) => _ExamRow(
                            titolo: e.titolo,
                            tipologia: _formatTipologia(e.tipologia),
                            data: e.data,
                            isCompletato: e.isCompletato,
                            isDark: isDark,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ExamDetailScreen(exam: e),
                              ),
                            ),
                          ))
                      .toList(),
                ),

              // Sezione attività
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'Attività',
                count: tasks.length,
                isDark: isDark,
                trailing: _AddInlineButton(
                  label: 'Aggiungi',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TaskFormScreen(
                        defaultCourseId: updatedCourse.id,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (tasks.isEmpty)
                _EmptyCard(
                    text: 'Nessuna attività collegata', isDark: isDark)
              else
                _ItemsContainer(
                  isDark: isDark,
                  children: tasks
                      .map((t) => _TaskRow(
                            task: t,
                            onToggle: () =>
                                provider.toggleTaskCompletion(t.id),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TaskFormScreen(
                                  taskToEdit: t,
                                  defaultCourseId: updatedCourse.id,
                                ),
                              ),
                            ),
                            onDelete: () async {
                              final c = await _confirmDeleteTask(
                                  context, t);
                              if (c == true && context.mounted) {
                                await provider.deleteTask(t.id);
                              }
                            },
                            isDark: isDark,
                          ))
                      .toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<bool?> _confirmDeleteTask(BuildContext context, Task t) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina attività'),
        content: Text('Eliminare "${t.titolo}"?'),
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
  }

  Future<void> _handleDelete(
    BuildContext context,
    PlannerProvider provider,
    Course course,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina corso'),
        content: Text(
            'Eliminare "${course.nome}"? Saranno eliminati anche esami e attività collegate.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Elimina',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (!context.mounted) return;
    if (confirm == true) {
      await provider.deleteCourse(course.id);
      if (!context.mounted) return;
      Navigator.pop(context);
    }
  }
}

class _HeroCard extends StatelessWidget {
  final Course course;
  final String statoLabel;
  final String votoOttenuto;
  final String votoDesiderato;
  final bool isDark;

  const _HeroCard({
    required this.course,
    required this.statoLabel,
    required this.votoOttenuto,
    required this.votoDesiderato,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statoColor = AppColors.statoCorso(course.stato);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.pastelRedDeep.withValues(alpha: 0.18)
            : AppColors.pastelRedLight,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CORSO',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.pastelRedDeep,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.nome,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : AppColors.pastelRedDeep,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.docente,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? Colors.white70
                            : AppColors.pastelRedDeep
                                .withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    Text(
                      course.cfu.toString(),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.pastelRedDeep,
                        height: 1.0,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'CFU',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.pastelRedDeep,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Chips di stato e voto
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatoChip(label: statoLabel, color: statoColor),
              if (course.votoOttenuto != null)
                _StatoChip(
                  label: '$votoOttenuto/30',
                  color: AppColors.success,
                ),
              if (course.votoDesiderato != null)
                _StatoChip(
                  label: 'obiettivo $votoDesiderato',
                  color: AppColors.pastelLavenderDeep,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// Chip per il testo
class _StatoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

// Info card (semestre, voto, ecc.)
class _MiniInfoCard extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _MiniInfoCard({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: valueColor ??
                  (isDark ? Colors.white : AppColors.textPrimary),
              letterSpacing: -0.2,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// Note Card (per Note e Materiale del corso)
class _NoteCard extends StatelessWidget {
  final String? note;
  final String? materiale;
  final bool isDark;

  const _NoteCard({
    required this.note,
    required this.materiale,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (materiale != null && materiale!.isNotEmpty) ...[
            Text(
              'MATERIALE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              materiale!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            if (note != null && note!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Divider(
                  height: 1,
                  thickness: 0.5,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.groupedDivider,
                ),
              ),
          ],
          if (note != null && note!.isNotEmpty) ...[
            Text(
              'NOTE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note!,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Section title (Esami, Attività, ecc.)
class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final Widget? trailing;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    required this.count,
    this.trailing,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

// Aggiunge inline accanto al titolo di sezione
class _AddInlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _AddInlineButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded,
                  size: 18, color: AppColors.iosBlue),
              const SizedBox(width: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.iosBlue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// Container Lista
class _ItemsContainer extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _ItemsContainer({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: _withDividers(children, isDark)),
    );
  }

  List<Widget> _withDividers(List<Widget> rows, bool isDark) {
    if (rows.length <= 1) return rows;
    final result = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      result.add(rows[i]);
      if (i < rows.length - 1) {
        result.add(Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Divider(
            height: 1,
            thickness: 0.5,
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : AppColors.groupedDivider,
          ),
        ));
      }
    }
    return result;
  }
}

// Empty Card (se nessun esame collegato)
class _EmptyCard extends StatelessWidget {
  final String text;
  final bool isDark;
  const _EmptyCard({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(fontSize: 14, color: AppColors.textMuted),
      ),
    );
  }
}


// Exam Row (dentro la card lista)
class _ExamRow extends StatelessWidget {
  final String titolo;
  final String tipologia;
  final DateTime data;
  final bool isCompletato;
  final bool isDark;
  final VoidCallback? onTap;

  const _ExamRow({
    required this.titolo,
    required this.tipologia,
    required this.data,
    required this.isCompletato,
    required this.isDark,
    this.onTap, 
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.pastelBlueLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.calendar_today_rounded,
              size: 16,
              color: AppColors.pastelBlueDeep,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titolo,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$tipologia · $dateStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white60
                        : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (isCompletato)
            Icon(Icons.check_circle_rounded,
                size: 20, color: AppColors.success)
          else
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
        ],
      ),
    ),
      ),
    );
  }
}

// Task row (con checkbox, tap modifica e swipe delete)
class _TaskRow extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final Future<void> Function()? onDelete;
  final bool isDark;

  const _TaskRow({
    required this.task,
    required this.onToggle,
    this.onTap,
    this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppColors.priorita(task.priorita);

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.completata
                    ? AppColors.iosBlue
                    : Colors.transparent,
                border: Border.all(
                  color: task.completata
                      ? AppColors.iosBlue
                      : (isDark
                          ? Colors.white38
                          : AppColors.textMuted),
                  width: 2,
                ),
              ),
              child: task.completata
                  ? const Icon(Icons.check_rounded,
                      size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.titolo,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : AppColors.textPrimary,
                decoration: task.completata
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: AppColors.textMuted,
                letterSpacing: -0.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              task.priorita.toUpperCase(),
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: priorityColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );

    Widget row = Material(
      color: Colors.transparent,
      child: InkWell(onTap: onTap, child: content),
    );

    if (onDelete != null) {
      return Dismissible(
        key: ValueKey('task_${task.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: AppColors.danger,
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          await onDelete!();
          // false perché la rimozione la fa il Provider via notifyListeners e non il Dismissible
          return false;
        },
        child: row,
      );
    }

    return row;
  }
}