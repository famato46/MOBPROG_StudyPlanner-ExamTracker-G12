import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/course.dart';
import '../providers/planner_provider.dart';
import '../utils/app_colors.dart';
import 'course_form_screen.dart';

/// CourseDetailScreen — Stile iOS Settings.
///
/// Layout:
///  - AppBar minimal con nome corso + matita modifica + cestino delete
///  - Gruppo "Informazioni" con righe label/valore separate da divider
///  - Gruppo "Esami" e "Attività" con stesso pattern Settings-like
class CourseDetailScreen extends StatelessWidget {
  final Course course;
  const CourseDetailScreen({super.key, required this.course});

  String _formatStato(String stato) {
    switch (stato) {
      case 'da_iniziare':
        return 'Da iniziare';
      case 'in_corso':
        return 'In corso';
      case 'da_ripassare':
        return 'Da ripassare';
      case 'completato':
        return 'Completato';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF000000)
        : AppColors.groupedBackground;

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
              icon: const Icon(
                Icons.chevron_left_rounded,
                size: 32,
              ),
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
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            children: [
              // ─── GRUPPO INFORMAZIONI ────────────────────────
              _GroupHeader(label: 'Informazioni'),
              _SettingsGroup(
                isDark: isDark,
                children: [
                  _SettingsRow(
                    label: 'Docente',
                    value: updatedCourse.docente,
                    isDark: isDark,
                  ),
                  _SettingsRow(
                    label: 'CFU',
                    value: updatedCourse.cfu.toString(),
                    isDark: isDark,
                  ),
                  _SettingsRow(
                    label: 'Semestre',
                    value: updatedCourse.semestre,
                    isDark: isDark,
                  ),
                  _SettingsRow(
                    label: 'Stato',
                    value: _formatStato(updatedCourse.stato),
                    valueColor:
                        AppColors.statoCorso(updatedCourse.stato),
                    isDark: isDark,
                  ),
                  if (updatedCourse.votoOttenuto != null)
                    _SettingsRow(
                      label: 'Voto ottenuto',
                      value: '${updatedCourse.votoOttenuto}/30',
                      valueColor: AppColors.success,
                      isDark: isDark,
                    ),
                  if (updatedCourse.votoDesiderato != null)
                    _SettingsRow(
                      label: 'Voto mirato',
                      value: '${updatedCourse.votoDesiderato}/30',
                      isDark: isDark,
                    ),
                ],
              ),

              // ─── GRUPPO NOTE / MATERIALE (se presenti) ───────
              if ((updatedCourse.note?.isNotEmpty ?? false) ||
                  (updatedCourse.materialeAssociato?.isNotEmpty ??
                      false)) ...[
                const SizedBox(height: 24),
                _GroupHeader(label: 'Risorse'),
                _SettingsGroup(
                  isDark: isDark,
                  children: [
                    if (updatedCourse.materialeAssociato?.isNotEmpty ??
                        false)
                      _SettingsMultilineRow(
                        label: 'Materiale',
                        value: updatedCourse.materialeAssociato!,
                        isDark: isDark,
                      ),
                    if (updatedCourse.note?.isNotEmpty ?? false)
                      _SettingsMultilineRow(
                        label: 'Note',
                        value: updatedCourse.note!,
                        isDark: isDark,
                      ),
                  ],
                ),
              ],

              // ─── GRUPPO ESAMI COLLEGATI ──────────────────────
              const SizedBox(height: 24),
              _GroupHeader(label: 'Esami (${exams.length})'),
              if (exams.isEmpty)
                _EmptyGroupRow(
                  text: 'Nessun esame collegato',
                  isDark: isDark,
                )
              else
                _SettingsGroup(
                  isDark: isDark,
                  children: exams
                      .map(
                        (e) => _ExamRow(
                          titolo: e.titolo,
                          tipologia: _formatTipologia(e.tipologia),
                          data: e.data,
                          isCompletato: e.isCompletato,
                          isDark: isDark,
                        ),
                      )
                      .toList(),
                ),

              // ─── GRUPPO ATTIVITÀ ─────────────────────────────
              const SizedBox(height: 24),
              _GroupHeader(label: 'Attività (${tasks.length})'),
              if (tasks.isEmpty)
                _EmptyGroupRow(
                  text: 'Nessuna attività collegata',
                  isDark: isDark,
                )
              else
                _SettingsGroup(
                  isDark: isDark,
                  children: tasks
                      .map(
                        (t) => _TaskRow(
                          titolo: t.titolo,
                          priorita: t.priorita,
                          completata: t.completata,
                          onToggle: () =>
                              provider.toggleTaskCompletion(t.id),
                          isDark: isDark,
                        ),
                      )
                      .toList(),
                ),
            ],
          ),
        );
      },
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

// ═══════════════════════════════════════════════════════════════
// GROUP HEADER (label uppercase sopra ogni gruppo, stile Settings)
// ═══════════════════════════════════════════════════════════════
class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 16, 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CONTAINER GRUPPO (card bianca arrotondata con righe e divider)
// ═══════════════════════════════════════════════════════════════
class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _SettingsGroup({
    required this.children,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E)
            : AppColors.groupedSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: _withDividers(children, isDark),
      ),
    );
  }

  /// Inserisce automaticamente i divider tra le righe (non in cima/fondo).
  List<Widget> _withDividers(List<Widget> rows, bool isDark) {
    if (rows.length <= 1) return rows;
    final result = <Widget>[];
    for (var i = 0; i < rows.length; i++) {
      result.add(rows[i]);
      if (i < rows.length - 1) {
        result.add(Padding(
          padding: const EdgeInsets.only(left: 16),
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

// ═══════════════════════════════════════════════════════════════
// SETTINGS ROW: label sx, valore dx, su una riga (Settings iOS)
// ═══════════════════════════════════════════════════════════════
class _SettingsRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool isDark;

  const _SettingsRow({
    required this.label,
    required this.value,
    this.valueColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 44),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : AppColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 16,
                color: valueColor ??
                    (isDark
                        ? Colors.white60
                        : AppColors.textSecondary),
                letterSpacing: -0.3,
                fontWeight: valueColor != null
                    ? FontWeight.w600
                    : FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MULTILINE ROW (per Note / Materiale): label sopra, valore sotto
// ═══════════════════════════════════════════════════════════════
class _SettingsMultilineRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _SettingsMultilineRow({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              color: isDark
                  ? Colors.white60
                  : AppColors.textSecondary,
              letterSpacing: -0.2,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY GROUP ROW (quando una sezione non ha elementi)
// ═══════════════════════════════════════════════════════════════
class _EmptyGroupRow extends StatelessWidget {
  final String text;
  final bool isDark;

  const _EmptyGroupRow({
    required this.text,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1C1E)
            : AppColors.groupedSurface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white60 : AppColors.textSecondary,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EXAM ROW (riga dentro il gruppo Esami)
// ═══════════════════════════════════════════════════════════════
class _ExamRow extends StatelessWidget {
  final String titolo;
  final String tipologia;
  final DateTime data;
  final bool isCompletato;
  final bool isDark;

  const _ExamRow({
    required this.titolo,
    required this.tipologia,
    required this.data,
    required this.isCompletato,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      constraints: const BoxConstraints(minHeight: 56),
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
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? Colors.white
                        : AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$tipologia · $dateStr',
                  style: TextStyle(
                    fontSize: 13,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TASK ROW (riga dentro il gruppo Attività, con checkbox toggle)
// ═══════════════════════════════════════════════════════════════
class _TaskRow extends StatelessWidget {
  final String titolo;
  final String priorita;
  final bool completata;
  final VoidCallback onToggle;
  final bool isDark;

  const _TaskRow({
    required this.titolo,
    required this.priorita,
    required this.completata,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppColors.priorita(priorita);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              // Checkbox circolare stile iOS
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completata
                      ? AppColors.iosBlue
                      : Colors.transparent,
                  border: Border.all(
                    color: completata
                        ? AppColors.iosBlue
                        : (isDark
                            ? Colors.white38
                            : AppColors.textMuted),
                    width: 2,
                  ),
                ),
                child: completata
                    ? const Icon(
                        Icons.check_rounded,
                        size: 14,
                        color: Colors.white,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  titolo,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark
                        ? Colors.white
                        : AppColors.textPrimary,
                    decoration: completata
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: AppColors.textMuted,
                    letterSpacing: -0.3,
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
                  priorita.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: priorityColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}