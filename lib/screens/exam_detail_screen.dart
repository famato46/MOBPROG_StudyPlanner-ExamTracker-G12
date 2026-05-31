import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/exam.dart';
import '../providers/planner_provider.dart';
import '../utils/app_colors.dart';
import 'exam_form_screen.dart';

/// ExamDetailScreen
class ExamDetailScreen extends StatelessWidget {
  final Exam exam;
  const ExamDetailScreen({super.key, required this.exam});

  String _formatTipologia(String t) {
    switch (t.toLowerCase()) {
      case 'scritto': 
        return 'Scritto';
      case 'orale':
        return 'Orale';
      case 'intercorso':
        return 'Intercorso';
      case 'consegna':
        return 'Consegna';
      case 'progetto':
        return 'Progetto';
      default:
        if (t.isEmpty) return t;
        return t[0].toUpperCase() + t.substring(1).toLowerCase();
    }
  }

  String _formatPriorita(String p) {
    switch (p) {
      case 'alta':
        return 'Alta';
      case 'media':
        return 'Media';
      case 'bassa':
        return 'Bassa';
      default:
        return p;
    }
  }

  String _formatVoto(int? voto) {
    if (voto == null) return '-';
    if (voto >= 31) return '30L';
    return voto.toString();
  }

  String _etichettaStato(Exam e) {
    if (e.stato == 'completato') return 'Completato';
    if (e.stato == 'annullato') return 'Annullato';
    if (e.isImminente) return 'Imminente';
    if (e.isPassato) return 'Passato';
    return 'Programmato';
  }

  Color _coloreStato(Exam e) {
    if (e.stato == 'completato') return AppColors.success;
    if (e.stato == 'annullato') return AppColors.textMuted;
    if (e.isImminente) return AppColors.danger;
    if (e.isPassato) return AppColors.textMuted;
    return AppColors.examsDeep;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF000000) : AppColors.background;

    return Consumer<PlannerProvider>(
      builder: (context, provider, child) {
        final updatedExam = provider.getExamById(exam.id) ?? exam;
        final corso = provider.getCourseById(updatedExam.courseId);
        final sessioni = provider.studySessions
            .where((s) => s.examId == updatedExam.id)
            .toList();

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
              updatedExam.titolo,
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
                    builder: (_) => ExamFormScreen(exam: updatedExam),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 22),
                color: AppColors.danger,
                onPressed: () =>
                    _handleDelete(context, provider, updatedExam),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              _HeroCard(
                exam: updatedExam,
                corso: corso?.nome ?? 'Corso non trovato',
                tipologia: _formatTipologia(updatedExam.tipologia),
                priorita: _formatPriorita(updatedExam.priorita),
                statoLabel: _etichettaStato(updatedExam),
                statoColor: _coloreStato(updatedExam),
                isDark: isDark,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _MiniInfoCard(
                      label: 'DATA',
                      value: DateFormat('dd MMM yyyy', 'it_IT')
                          .format(updatedExam.data),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniInfoCard(
                      label: updatedExam.stato == 'completato'
                          ? 'VOTO'
                          : 'PRIORITÀ',
                      value: updatedExam.stato == 'completato'
                          ? (updatedExam.voto != null
                              ? '${_formatVoto(updatedExam.voto)} / 30'
                              : '—')
                          : _formatPriorita(updatedExam.priorita),
                      valueColor: updatedExam.stato == 'completato'
                          ? AppColors.success
                          : AppColors.priorita(updatedExam.priorita),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),

              // NOTE
              if (updatedExam.note != null &&
                  updatedExam.note!.isNotEmpty) ...[
                const SizedBox(height: 14),
                _NoteCard(note: updatedExam.note!, isDark: isDark),
              ],

              // SESSIONI DI STUDIO COLLEGATE 
              const SizedBox(height: 24),
              _SectionTitle(
                title: 'Sessioni di studio',
                count: sessioni.length,
                isDark: isDark,
              ),
              const SizedBox(height: 8),
              if (sessioni.isEmpty)
                _EmptyCard(
                    text: 'Nessuna sessione collegata',
                    isDark: isDark)
              else
                _ItemsContainer(
                  isDark: isDark,
                  children: sessioni
                      .map((s) => _SessionRow(
                            titolo: s.titolo,
                            durata: s.durataPianificata,
                            tipo: s.tipo,
                            completata: s.completata,
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

  Future<void> _handleDelete(
    BuildContext context,
    PlannerProvider provider,
    Exam exam,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina esame'),
        content: Text('Eliminare "${exam.titolo}"?'),
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
      await provider.deleteExam(exam.id);
      if (!context.mounted) return;
      Navigator.pop(context);
    }
  }
}

// HERO CARD: card grande pastello BLU
class _HeroCard extends StatelessWidget {
  final Exam exam;
  final String corso;
  final String tipologia;
  final String priorita;
  final String statoLabel;
  final Color statoColor;
  final bool isDark;

  const _HeroCard({
    required this.exam,
    required this.corso,
    required this.tipologia,
    required this.priorita,
    required this.statoLabel,
    required this.statoColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final adesso = DateTime.now();
    final dataSoloGiorno =
        DateTime(exam.data.year, exam.data.month, exam.data.day);
    final oggiSoloGiorno =
        DateTime(adesso.year, adesso.month, adesso.day);
    final giorni = dataSoloGiorno.difference(oggiSoloGiorno).inDays;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.pastelBlueDeep.withValues(alpha: 0.18)
            : AppColors.pastelBlueLight,
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
                      tipologia.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                        color: AppColors.pastelBlueDeep,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      exam.titolo,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? Colors.white
                            : AppColors.pastelBlueDeep,
                        letterSpacing: -0.5,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
              ),
              _CountdownBadge(
                giorni: giorni,
                completato: exam.stato == 'completato',
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Chips di stato e priorità
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _StatoChip(label: statoLabel, color: statoColor),
              _StatoChip(
                label: 'Priorità $priorita',
                color: AppColors.priorita(exam.priorita),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CountdownBadge extends StatelessWidget {
  final int giorni;
  final bool completato;
  const _CountdownBadge({required this.giorni, required this.completato});

  @override
  Widget build(BuildContext context) {
    String big;
    String small;
    if (completato) {
      big = '✓';
      small = 'fatto';
    } else if (giorni == 0) {
      big = 'OGGI';
      small = '';
    } else if (giorni > 0) {
      big = giorni.toString();
      small = giorni == 1 ? 'giorno' : 'giorni';
    } else {
      big = giorni.abs().toString();
      small = 'gg fa';
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            big,
            style: TextStyle(
              fontSize: big == 'OGGI' || big == '✓' ? 18 : 22,
              fontWeight: FontWeight.w700,
              color: AppColors.pastelBlueDeep,
              height: 1.0,
              letterSpacing: -0.5,
            ),
          ),
          if (small.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              small,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppColors.pastelBlueDeep,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Chip bianco
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

// MINI INFO CARD
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

// NOTE CARD
class _NoteCard extends StatelessWidget {
  final String note;
  final bool isDark;

  const _NoteCard({required this.note, required this.isDark});

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
            note,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// SECTION TITLE
class _SectionTitle extends StatelessWidget {
  final String title;
  final int count;
  final bool isDark;

  const _SectionTitle({
    required this.title,
    required this.count,
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
        ],
      ),
    );
  }
}

// CONTAINER LISTA
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

// EMPTY CARD
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

// SESSION ROW (riga sessione di studio)
class _SessionRow extends StatelessWidget {
  final String titolo;
  final int durata;
  final String tipo;
  final bool completata;
  final bool isDark;

  const _SessionRow({
    required this.titolo,
    required this.durata,
    required this.tipo,
    required this.completata,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.pastelGreenLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.timer_outlined,
              size: 16,
              color: AppColors.pastelGreenDeep,
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
                  '$durata min · $tipo',
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
          if (completata)
            Icon(Icons.check_circle_rounded,
                size: 20, color: AppColors.success),
        ],
      ),
    );
  }
}