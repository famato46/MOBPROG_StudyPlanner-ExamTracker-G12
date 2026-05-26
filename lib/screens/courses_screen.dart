import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../models/course.dart';
import '../utils/app_colors.dart';
import 'course_detail_screen.dart';
import 'course_form_screen.dart';

class CoursesScreen extends StatefulWidget {
  const CoursesScreen({super.key});

  @override
  State<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends State<CoursesScreen> {
  String _searchQuery = '';
  String _filterStato = 'tutti';
  String _sortBy = 'nome';

  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Course> _filteredCourses(List<Course> courses) {
    var filtered = courses.where((c) {
      final matchSearch =
          c.nome.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              c.docente.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchStato = _filterStato == 'tutti' || c.stato == _filterStato;
      return matchSearch && matchStato;
    }).toList();

    switch (_sortBy) {
      case 'nome':
        filtered.sort((a, b) => a.nome.compareTo(b.nome));
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

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
        title: const Text('Corsi'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'nome', child: Text('Ordina per nome')),
              PopupMenuItem(value: 'cfu', child: Text('Ordina per CFU')),
              PopupMenuItem(value: 'stato', child: Text('Ordina per stato')),
            ],
          ),
        ],
      ),
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final courses = _filteredCourses(provider.courses);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cerca per nome o docente...',
                    prefixIcon: Icon(Icons.search, color: AppColors.courses),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppColors.surface,
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    ('tutti', 'Tutti'),
                    ('da_iniziare', 'Da iniziare'),
                    ('in_corso', 'In corso'),
                    ('da_ripassare', 'Da ripassare'),
                    ('completato', 'Completato'),
                    ('superato', 'Superato'),
                  ].map((entry) {
                    final selected = _filterStato == entry.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(entry.$2),
                        selected: selected,
                        selectedColor: AppColors.courses.withOpacity(0.2),
                        checkmarkColor: AppColors.coursesDark,
                        onSelected: (_) =>
                            setState(() => _filterStato = entry.$1),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Expanded(
                child: courses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.school_outlined,
                                size: 64, color: AppColors.courses),
                            const SizedBox(height: 16),
                            Text(
                              provider.courses.isEmpty
                                  ? 'Nessun corso aggiunto.\nPremi + per iniziare!'
                                  : 'Nessun corso trovato.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.coursesDark),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: courses.length,
                        itemBuilder: (context, index) {
                          final course = courses[index];
                          return Dismissible(
                            key: ValueKey(course.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin:
                                  const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.danger,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.delete,
                                  color: Colors.white),
                            ),
                            confirmDismiss: (_) async {
                              return await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text('Elimina corso'),
                                  content: Text(
                                      'Eliminare "${course.nome}"? Saranno eliminati anche gli esami e le attività collegate.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text('Annulla'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: Text('Elimina',
                                          style: TextStyle(
                                              color: AppColors.danger)),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (_) {
                              provider.deleteCourse(course.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('${course.nome} eliminato')),
                              );
                            },
                            child: _CourseCard(
                              course: course,
                              statoColor: AppColors.statoCorso(course.stato),
                              statoLabel: _statoLabel(course.stato),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      CourseDetailScreen(course: course),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.courses,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CourseFormScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  final Course course;
  final Color statoColor;
  final String statoLabel;
  final VoidCallback onTap;

  const _CourseCard({
    required this.course,
    required this.statoColor,
    required this.statoLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: statoColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.nome,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      course.docente,
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _Chip(
                            label: '${course.cfu} CFU',
                            color: AppColors.courses),
                        const SizedBox(width: 6),
                        _Chip(label: statoLabel, color: statoColor),
                        if (course.votoOttenuto != null) ...[
                          const SizedBox(width: 6),
                          _Chip(
                            label: '${course.votoOttenuto}/30',
                            color: AppColors.success,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}