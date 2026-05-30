import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../models/course.dart';
import '../utils/app_colors.dart';
import 'course_detail_screen.dart';
import 'course_form_screen.dart';

/// CoursesScreen — Lista corsi Apple-style.
class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen>
    with TickerProviderStateMixin {
  String _searchQuery = '';
  String _filterStato = 'tutti';
  String _filterSemestre = 'tutti_sem';
  String _sortBy = 'nome';

  final TextEditingController _searchController = TextEditingController();

  static const List<(String, String)> _statiOptions = [
    ('tutti', 'Tutti'),
    ('da_iniziare', 'Da iniziare'),
    ('in_corso', 'In corso'),
    ('completato', 'Frequentato'),
    ('superato', 'Superato'),
  ];

static const List<(String, String)> _semestriOptions = [
  ('tutti_sem', 'Tutti i semestri'),
  ('1° Semestre · Anno I', '1° sem · Anno I'),
  ('2° Semestre · Anno I', '2° sem · Anno I'),
  ('1° Semestre · Anno II', '1° sem · Anno II'),
  ('2° Semestre · Anno II', '2° sem · Anno II'),
  ('1° Semestre · Anno III', '1° sem · Anno III'),
  ('2° Semestre · Anno III', '2° sem · Anno III'),
];

  late final TabController _statoTabController;

  @override
  void initState() {
    super.initState();
    _statoTabController = TabController(
      length: _statiOptions.length,
      vsync: this,
    )..addListener(() {
        if (_statoTabController.indexIsChanging) return;
        setState(() =>
            _filterStato = _statiOptions[_statoTabController.index].$1);
      });
  }

  @override
  void dispose() {
    _statoTabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Course> _filteredCourses(List<Course> courses) {
    var filtered = courses.where((c) {
      final q = _searchQuery.toLowerCase();
      final matchSearch = c.nome.toLowerCase().contains(q) ||
          c.docente.toLowerCase().contains(q);
      final matchStato =
          _filterStato == 'tutti' || c.stato == _filterStato;
      final matchSemestre = _filterSemestre == 'tutti_sem' ||
          c.semestre == _filterSemestre;
      return matchSearch && matchStato && matchSemestre;
    }).toList();

    switch (_sortBy) {
      case 'nome':
        filtered.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
        break;
      case 'cfu':
        filtered.sort((a, b) => b.cfu.compareTo(a.cfu));
        break;
      case 'stato':
        filtered.sort((a, b) => a.stato.compareTo(b.stato));
        break;
    }
    return filtered;
  }

  String _statoLabel(String stato) {
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

          final courses = _filteredCourses(provider.courses);

          return SafeArea(
            child: Column(
              children: [
                _CoursesHeader(
                  total: provider.courses.length,
                  visible: courses.length,
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
                const SizedBox(height: 4),
                // ── Tab stati con TabBar nativo auto-scroll ──
                Padding(
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
                      controller: _statoTabController,
                      isScrollable: true,
                      tabAlignment: TabAlignment.start,
                      indicator: BoxDecoration(
                        color: AppColors.pastelRed,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      labelColor: Colors.white,
                      unselectedLabelColor: isDark
                          ? Colors.white70
                          : AppColors.textSecondary,
                      labelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2),
                      unselectedLabelStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2),
                      splashFactory: NoSplash.splashFactory,
                      overlayColor:
                          WidgetStateProperty.all(Colors.transparent),
                      tabs: _statiOptions
                          .map((s) => Tab(text: s.$2))
                          .toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // ── Filtro semestri con TabBar nativo auto-scroll ──
                _FilterRow(
                  options: _semestriOptions,
                  current: _filterSemestre,
                  onSelected: (v) => setState(() => _filterSemestre = v),
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: courses.isEmpty
                      ? _EmptyState(
                          hasAnyCourse: provider.courses.isNotEmpty,
                          isDark: isDark,
                        )
                      : ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(20, 4, 20, 100),
                          itemCount: courses.length,
                          itemBuilder: (context, index) {
                            final course = courses[index];
                            return _DismissibleCourse(
                              course: course,
                              statoColor:
                                  AppColors.statoCorso(course.stato),
                              statoLabel: _statoLabel(course.stato),
                              onConfirmDelete: () =>
                                  _confirmDelete(context, course),
                              onDelete: () async {
                                await provider.deleteCourse(course.id);
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        '${course.nome} eliminato'),
                                  ),
                                );
                              },
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CourseDetailScreen(
                                      course: course),
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
        color: AppColors.pastelRed,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CourseFormScreen()),
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Course course) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina corso'),
        content: Text(
            'Eliminare "${course.nome}"? Saranno eliminati anche gli esami e le attività collegate.'),
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

// ═══════════════════════════════════════════════════════════════
// FILTER ROW SEMESTRI — TabBar nativo con auto-scroll
// ═══════════════════════════════════════════════════════════════
class _FilterRow extends StatefulWidget {
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
  State<_FilterRow> createState() => _FilterRowState();
}

class _FilterRowState extends State<_FilterRow>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  int get _currentIndex {
    final i = widget.options.indexWhere((o) => o.$1 == widget.current);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: widget.options.length,
      vsync: this,
      initialIndex: _currentIndex,
    );
  }

  @override
  void didUpdateWidget(_FilterRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current) {
      _tabController.animateTo(_currentIndex);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          onTap: (i) => widget.onSelected(widget.options[i].$1),
          indicator: BoxDecoration(
            color: AppColors.pastelRed,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: widget.isDark
              ? Colors.white70
              : AppColors.textSecondary,
          labelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2),
          unselectedLabelStyle: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: widget.options.map((o) => Tab(text: o.$2)).toList(),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// HEADER
// ═══════════════════════════════════════════════════════════════
class _CoursesHeader extends StatelessWidget {
  final int total;
  final int visible;
  final String sortBy;
  final ValueChanged<String> onSortChanged;
  final bool isDark;

  const _CoursesHeader({
    required this.total,
    required this.visible,
    required this.sortBy,
    required this.onSortChanged,
    required this.isDark,
  });

  String _sortLabel(String s) {
    switch (s) {
      case 'nome': return 'Nome';
      case 'cfu': return 'CFU';
      case 'stato': return 'Stato';
      default: return s;
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryColor = isDark ? Colors.white70 : AppColors.textSecondary;

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
                  'Corsi',
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
                  visible == total
                      ? '$total ${total == 1 ? "corso" : "corsi"}'
                      : '$visible di $total visibili',
                  style: TextStyle(fontSize: 14, color: secondaryColor),
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
              _sortItem('nome', 'Nome A-Z', Icons.sort_by_alpha),
              _sortItem('cfu', 'CFU (alti prima)', Icons.school_outlined),
              _sortItem('stato', 'Stato', Icons.filter_list_rounded),
            ],
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  Icon(Icons.sort_rounded, size: 16, color: secondaryColor),
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

  PopupMenuItem<String> _sortItem(String value, String label, IconData icon) {
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

// ═══════════════════════════════════════════════════════════════
// SEARCH BAR
// ═══════════════════════════════════════════════════════════════
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
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
        cursorColor: AppColors.pastelRedDeep,
        decoration: InputDecoration(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          hintText: 'Cerca per nome o docente',
          hintStyle: TextStyle(fontSize: 15, color: AppColors.textMuted),
          prefixIcon:
              Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
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

// ═══════════════════════════════════════════════════════════════
// DISMISSIBLE COURSE
// ═══════════════════════════════════════════════════════════════
class _DismissibleCourse extends StatelessWidget {
  final Course course;
  final Color statoColor;
  final String statoLabel;
  final Future<bool?> Function() onConfirmDelete;
  final Future<void> Function() onDelete;
  final VoidCallback onTap;
  final bool isDark;

  const _DismissibleCourse({
    required this.course,
    required this.statoColor,
    required this.statoLabel,
    required this.onConfirmDelete,
    required this.onDelete,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(course.id),
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
      child: _CourseCard(
        course: course,
        statoColor: statoColor,
        statoLabel: statoLabel,
        onTap: onTap,
        isDark: isDark,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// COURSE CARD
// ═══════════════════════════════════════════════════════════════
class _CourseCard extends StatelessWidget {
  final Course course;
  final Color statoColor;
  final String statoLabel;
  final VoidCallback onTap;
  final bool isDark;

  const _CourseCard({
    required this.course,
    required this.statoColor,
    required this.statoLabel,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? Colors.white : AppColors.textPrimary;
    final secondaryColor = isDark ? Colors.white60 : AppColors.textSecondary;

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
                Container(
                  width: 4,
                  height: 56,
                  decoration: BoxDecoration(
                    color: statoColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.nome,
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
                        course.docente,
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
                            label: '${course.cfu} CFU',
                            color: AppColors.pastelRedDeep,
                          ),
                          _Badge(label: statoLabel, color: statoColor),
                          if (course.votoOttenuto != null)
                            _Badge(
                              label: course.votoOttenuto! >= 31
                                  ? '30L'
                                  : '${course.votoOttenuto}/30',
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

// ═══════════════════════════════════════════════════════════════
// BADGE
// ═══════════════════════════════════════════════════════════════
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.1,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final bool hasAnyCourse;
  final bool isDark;

  const _EmptyState({required this.hasAnyCourse, required this.isDark});

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
              color: AppColors.pastelRedLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.school_rounded,
              size: 36,
              color: AppColors.pastelRedDeep,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasAnyCourse ? 'Nessun corso trovato' : 'Nessun corso aggiunto',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hasAnyCourse
                ? 'Prova a cambiare i filtri'
                : 'Premi + per aggiungere il primo',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION FAB
// ═══════════════════════════════════════════════════════════════
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
        heroTag: 'fab_courses',
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
