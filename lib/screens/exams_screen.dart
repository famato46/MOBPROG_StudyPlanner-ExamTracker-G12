import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../models/exam.dart';
import '../utils/app_colors.dart';
import 'exam_form_screen.dart';
import 'exam_detail_screen.dart';

/// ExamsScreen — Lista esami Apple-style, riprende fedelmente il
/// pattern visivo di CoursesScreen (large title, search bar, filter
/// pills, dismissible card con badge).
///
/// Differenze rispetto a CoursesScreen:
///  - Tab orizzontale (Programmati / Completati / Annullati) sopra
///    i filtri per separare gli stati temporali richiesti dalla traccia.
///  - Filtri pill per tipologia (esame/intercorso/consegna/progetto).
///  - FAB pastel blu invece di pastel rosso.
class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen>
    with SingleTickerProviderStateMixin {
  String _searchQuery = '';
  String _filterTipologia = 'tutti';
  String _sortBy = 'data';
  // Inizializzato direttamente nella dichiarazione del campo invece di
  // usare `late final` + initState. Più robusto: anche se per qualche
  // motivo build() viene chiamato prima di initState (es. dopo un errore
  // recuperato), il controller esiste già.
  TabController? _tabController;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _tabController?.removeListener(_onTabChanged);
    _tabController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Color _coloreEsame(Exam e) {
    if (e.stato == 'completato') return AppColors.success;
    if (e.stato == 'annullato') return AppColors.textMuted;
    if (e.isImminente) return AppColors.danger;
    return AppColors.examsDeep;
  }

  String _etichettaStato(Exam e) {
    if (e.stato == 'completato') return 'Completato';
    if (e.stato == 'annullato') return 'Annullato';
    if (e.isImminente) return 'Imminente';
    if (e.isPassato) return 'Passato';
    return 'Programmato';
  }

  List<Exam> _processList(List<Exam> base) {
    var filtered = base.where((e) {
      final q = _searchQuery.toLowerCase();
      final matchSearch =
          q.isEmpty || e.titolo.toLowerCase().contains(q);
      final matchTipologia = _filterTipologia == 'tutti' ||
          e.tipologia.toLowerCase() == _filterTipologia;
      return matchSearch && matchTipologia;
    }).toList();

    if (_sortBy == 'data') {
      filtered.sort((a, b) => a.data.compareTo(b.data));
    } else {
      final order = ['alta', 'media', 'bassa'];
      filtered.sort((a, b) =>
          order.indexOf(a.priorita).compareTo(order.indexOf(b.priorita)));
    }
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? Theme.of(context).colorScheme.surface
        : AppColors.background;

    return Scaffold(
      backgroundColor: bgColor,
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Split per stato (Tab)
          final programmati = provider.exams
              .where((e) =>
                  e.stato != 'completato' && e.stato != 'annullato')
              .toList();
          final completati =
              provider.exams.where((e) => e.stato == 'completato').toList();
          final annullati =
              provider.exams.where((e) => e.stato == 'annullato').toList();

          // Se per qualche motivo il controller non è ancora pronto
          // (transizione di hot reload, ecc.) mostriamo un loader vuoto
          // invece di esplodere. In condizioni normali initState ha già
          // creato il controller, quindi questo ramo non viene mai preso.
          final tabController = _tabController;
          if (tabController == null) {
            return const Center(child: CircularProgressIndicator());
          }

          // Lista visibile in base al tab corrente
          final examsCurrent = tabController.index == 0
              ? programmati
              : tabController.index == 1
                  ? completati
                  : annullati;
          final examsVisible = _processList(examsCurrent);

          return SafeArea(
            child: Column(
              children: [
                _ExamsHeader(
                  total: provider.exams.length,
                  visible: examsVisible.length,
                  sortBy: _sortBy,
                  onSortChanged: (v) => setState(() => _sortBy = v),
                  isDark: isDark,
                ),
                _SearchBar(
                  controller: _searchController,
                  hasQuery: _searchQuery.isNotEmpty,
                  onChanged: (val) => setState(() => _searchQuery = val),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 8),
                // Tab orizzontale (3 stati temporali)
                _ExamTabBar(
                  controller: tabController,
                  counts: [
                    programmati.length,
                    completati.length,
                    annullati.length,
                  ],
                  isDark: isDark,
                ),
                const SizedBox(height: 12),
                _FilterRow(
                  options: const [
                    ('tutti', 'Tutti'),
                    ('esame', 'Esami'),
                    ('intercorso', 'Intercorsi'),
                    ('consegna', 'Consegne'),
                    ('progetto', 'Progetti'),
                  ],
                  current: _filterTipologia,
                  onSelected: (v) =>
                      setState(() => _filterTipologia = v),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: examsVisible.isEmpty
                      ? _EmptyState(
                          hasAnyExam: provider.exams.isNotEmpty,
                          isDark: isDark,
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 100),
                          itemCount: examsVisible.length,
                          itemBuilder: (context, index) {
                            final exam = examsVisible[index];
                            final corso =
                                provider.getCourseById(exam.courseId);
                            return _DismissibleExam(
                              exam: exam,
                              corsoNome: corso?.nome,
                              colore: _coloreEsame(exam),
                              etichetta: _etichettaStato(exam),
                              onConfirmDelete: () =>
                                  _confirmDelete(context, exam),
                              onDelete: () async {
                                await provider.deleteExam(exam.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('${exam.titolo} eliminato'),
                                  ),
                                );
                              },
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExamDetailScreen(exam: exam),
                                ),
                              ),
                              isDark: isDark,
                            );
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _SectionFab(
        color: AppColors.pastelBlue,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamFormScreen()),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Exam exam) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina esame'),
        content: Text(
            'Eliminare "${exam.titolo}"? Saranno eliminate anche le sessioni collegate.'),
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
  }
}

// ═══════════════════════════════════════════════════════════════════
// HEADER (large title + sort menu)
// ═══════════════════════════════════════════════════════════════════
class _ExamsHeader extends StatelessWidget {
  final int total;
  final int visible;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final bool isDark;

  const _ExamsHeader({
    required this.total,
    required this.visible,
    required this.sortBy,
    required this.onSortChanged,
    required this.isDark,
  });

  String _sortLabel(String s) {
    switch (s) {
      case 'data':
        return 'Data';
      case 'priorita':
        return 'Priorità';
      default:
        return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryColor =
        isDark ? Colors.white70 : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Esami',
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.2,
                    height: 1.05,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  total == 0
                      ? 'Nessun esame'
                      : visible == total
                          ? '$total ${total == 1 ? "esame" : "esami"}'
                          : '$visible di $total visibili',
                  style:
                      TextStyle(fontSize: 14, color: secondaryColor),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            color: isDark ? const Color(0xFF2A2A2C) : AppColors.surface,
            position: PopupMenuPosition.under,
            onSelected: onSortChanged,
            itemBuilder: (_) => [
              _sortItem('data', 'Data più vicina', Icons.calendar_today),
              _sortItem(
                  'priorita', 'Priorità (alta prima)', Icons.flag_outlined),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sort_rounded,
                      size: 16, color: secondaryColor),
                  const SizedBox(width: 6),
                  Text(
                    _sortLabel(sortBy),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _sortItem(
      String value, String label, IconData icon) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// SEARCH BAR (identica alla courses_screen ma con accent blu)
// ═══════════════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final bool isDark;

  const _SearchBar({
    required this.controller,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.black.withValues(alpha: 0.05);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        cursorColor: AppColors.examsDeep,
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          hintText: 'Cerca per titolo',
          hintStyle: TextStyle(
              fontSize: 15, color: AppColors.textMuted),
          prefixIcon: Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 20),
          suffixIcon: hasQuery
              ? IconButton(
                  icon: Icon(Icons.cancel_rounded,
                      color: AppColors.textMuted, size: 18),
                  onPressed: onClear,
                )
              : null,
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// TAB BAR PER STATI (Programmati / Completati / Annullati)
// ═══════════════════════════════════════════════════════════════════
class _ExamTabBar extends StatelessWidget {
  final TabController controller;
  final List<int> counts;
  final bool isDark;

  const _ExamTabBar({
    required this.controller,
    required this.counts,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: AppColors.pastelBlue,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor:
              isDark ? Colors.white70 : AppColors.textSecondary,
          labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3),
          unselectedLabelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.3),
          splashFactory: NoSplash.splashFactory,
          overlayColor:
              WidgetStateProperty.all(Colors.transparent),
          tabs: [
            // Label complete. Il FittedBox scala il testo verso il basso
            // SOLO se non ci sta nello spazio del tab, così evitiamo il
            // troncamento "Completati (0" senza abbreviare a priori.
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Programmati (${counts[0]})'),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Completati (${counts[1]})'),
              ),
            ),
            Tab(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Annullati (${counts[2]})'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// FILTER PILL ROW (orizzontale)
// ═══════════════════════════════════════════════════════════════════
class _FilterRow extends StatelessWidget {
  final List<(String, String)> options;
  final String current;
  final ValueChanged<String> onSelected;
  final bool isDark;

  const _FilterRow({
    required this.options,
    required this.current,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (value, label) = options[i];
          final selected = current == value;
          return _FilterPill(
            label: label,
            selected: selected,
            onTap: () => onSelected(value),
            isDark: isDark,
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _FilterPill({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected
        ? AppColors.pastelBlue
        : (isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.surface);
    final fg = selected
        ? Colors.white
        : (isDark ? Colors.white70 : AppColors.textSecondary);
    final border = selected
        ? AppColors.pastelBlue
        : (isDark
            ? Colors.white.withValues(alpha: 0.1)
            : AppColors.border);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
// CARD ESAME (swipe-to-delete)
// ═══════════════════════════════════════════════════════════════════
class _DismissibleExam extends StatelessWidget {
  final Exam exam;
  final String? corsoNome;
  final Color colore;
  final String etichetta;
  final Future<bool?> Function() onConfirmDelete;
  final Future<void> Function() onDelete;
  final VoidCallback onTap;
  final bool isDark;

  const _DismissibleExam({
    required this.exam,
    required this.corsoNome,
    required this.colore,
    required this.etichetta,
    required this.onConfirmDelete,
    required this.onDelete,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(exam.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      confirmDismiss: (_) async => await onConfirmDelete() ?? false,
      onDismissed: (_) => onDelete(),
      child: _ExamCard(
        exam: exam,
        corsoNome: corsoNome,
        colore: colore,
        etichetta: etichetta,
        onTap: onTap,
        isDark: isDark,
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final String? corsoNome;
  final Color colore;
  final String etichetta;
  final VoidCallback onTap;
  final bool isDark;

  const _ExamCard({
    required this.exam,
    required this.corsoNome,
    required this.colore,
    required this.etichetta,
    required this.onTap,
    required this.isDark,
  });

  IconData _iconaTipologia(String tipologia) {
    switch (tipologia.toLowerCase()) {
      case 'esame':
        return Icons.school_rounded;
      case 'intercorso':
        return Icons.rate_review_rounded;
      case 'consegna':
        return Icons.alarm_rounded;
      case 'progetto':
        return Icons.analytics_rounded;
      default:
        return Icons.assignment_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor =
        isDark ? Colors.white : AppColors.textPrimary;
    final secondaryColor =
        isDark ? Colors.white60 : AppColors.textSecondary;
    final dataString =
        '${exam.data.day.toString().padLeft(2, '0')}/${exam.data.month.toString().padLeft(2, '0')}/${exam.data.year}';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.border,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icona pastello con bg colorato in base allo stato
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colore.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _iconaTipologia(exam.tipologia),
                    color: colore,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exam.titolo,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        corsoNome ?? 'Corso non trovato',
                        style: TextStyle(
                          fontSize: 13,
                          color: secondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _Badge(
                            label: dataString,
                            color: AppColors.examsDeep,
                            icon: Icons.calendar_today_rounded,
                          ),
                          _Badge(
                            label: exam.priorita.toUpperCase(),
                            color: AppColors.priorita(exam.priorita),
                          ),
                          _Badge(label: etichetta, color: colore),
                          if (exam.stato == 'completato' &&
                              exam.voto != null)
                            _Badge(
                              label: exam.voto! >= 31
                                  ? '30L'
                                  : '${exam.voto}/30',
                              color: AppColors.success,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    color: isDark ? Colors.white38 : Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasAnyExam;
  final bool isDark;

  const _EmptyState({
    required this.hasAnyExam,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.pastelBlueLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.calendar_month_rounded,
              size: 36,
              color: AppColors.pastelBlueDeep,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasAnyExam ? 'Nessun esame trovato' : 'Nessun esame aggiunto',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasAnyExam
                ? 'Prova a cambiare i filtri'
                : 'Premi + per aggiungere il primo',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? Colors.white60
                  : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionFab extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const _SectionFab({required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.55),
            blurRadius: 18,
            spreadRadius: -2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: FloatingActionButton(
        heroTag: 'fab_exams',
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const CircleBorder(),
        onPressed: onPressed,
        child: const Icon(Icons.add_rounded, size: 28),
      ),
    );
  }
}