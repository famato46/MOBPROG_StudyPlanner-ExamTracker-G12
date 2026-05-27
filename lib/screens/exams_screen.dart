import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/planner_provider.dart';
import '../models/exam.dart';
import '../utils/app_colors.dart';
import 'exam_form_screen.dart';
import 'exam_detail_screen.dart';

class ExamsScreen extends StatefulWidget {
  const ExamsScreen({super.key});

  @override
  State<ExamsScreen> createState() => _ExamsScreenState();
}

class _ExamsScreenState extends State<ExamsScreen> {
  String _filterStato = 'tutti';
  String _filterTipologia = 'tutti';
  String _sortBy = 'data';

  // Riquadrino titolo — stesso pattern di courses_screen
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
          Icon(Icons.calendar_today, size: 20,
              color: isDark ? Colors.white : AppColors.exams),
          const SizedBox(width: 8),
          Text('Esami e Scadenze',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.exams,
              )),
        ],
      ),
    );
  }

  // Colore in base allo stato dell'esame
  Color _coloreEsame(Exam e) {
    if (e.isCompletato) return AppColors.success;
    if (e.isImminente) return AppColors.danger;
    if (e.isPassato) return AppColors.textMuted;
    return AppColors.exams;
  }

  String _etichettaStato(Exam e) {
    if (e.isPassato && !e.isCompletato) return 'Passato';
    if (e.isImminente) return 'Imminente';
    switch (e.stato) {
      case 'completato': return 'Completato';
      case 'annullato': return 'Annullato';
      default: return 'Programmato';
    }
  }

  List<Exam> _filteredExams(List<Exam> exams) {
    var filtered = exams.where((e) {
      final matchStato =
          _filterStato == 'tutti' || e.stato == _filterStato;
      final matchTipo =
          _filterTipologia == 'tutti' || e.tipologia == _filterTipologia;
      return matchStato && matchTipo;
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
    return Scaffold(
      appBar: AppBar(
        title: _buildTitleBadge(context),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (val) => setState(() => _sortBy = val),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'data', child: Text('Ordina per data')),
              PopupMenuItem(
                  value: 'priorita', child: Text('Ordina per priorità')),
            ],
          ),
        ],
      ),
      body: Consumer<PlannerProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final exams = _filteredExams(provider.exams);

          return Column(
            children: [
              // Filtri tipologia
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    ('tutti', 'Tutti'),
                    ('esame', 'Esame'),
                    ('appello', 'Appello'),
                    ('consegna', 'Consegna'),
                    ('progetto', 'Progetto'),
                  ].map((entry) {
                    final selected = _filterTipologia == entry.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(entry.$2),
                        selected: selected,
                        selectedColor: AppColors.exams.withOpacity(0.2),
                        checkmarkColor: AppColors.examsDark,
                        onSelected: (_) =>
                            setState(() => _filterTipologia = entry.$1),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Filtri stato
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(
                    left: 12, right: 12, bottom: 8),
                child: Row(
                  children: [
                    ('tutti', 'Tutti'),
                    ('programmato', 'Programmato'),
                    ('completato', 'Completato'),
                    ('annullato', 'Annullato'),
                  ].map((entry) {
                    final selected = _filterStato == entry.$1;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(entry.$2),
                        selected: selected,
                        selectedColor: AppColors.exams.withOpacity(0.15),
                        checkmarkColor: AppColors.examsDark,
                        onSelected: (_) =>
                            setState(() => _filterStato = entry.$1),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Lista esami
              Expanded(
                child: exams.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today,
                                size: 64, color: AppColors.exams),
                            const SizedBox(height: 16),
                            Text(
                              provider.exams.isEmpty
                                  ? 'Nessun esame aggiunto.\nPremi + per iniziare!'
                                  : 'Nessun esame trovato.',
                              textAlign: TextAlign.center,
                              style:
                                  TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        itemCount: exams.length,
                        itemBuilder: (context, index) {
                          final exam = exams[index];
                          final colore = _coloreEsame(exam);

                          return Dismissible(
                            key: ValueKey(exam.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              margin: const EdgeInsets.symmetric(
                                  vertical: 4),
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
                                  title: const Text('Elimina esame'),
                                  content: Text(
                                      'Eliminare "${exam.titolo}"?'),
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
                              provider.deleteExam(exam.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(
                                        '${exam.titolo} eliminato')),
                              );
                            },
                            child: _ExamCard(
                              exam: exam,
                              colore: colore,
                              etichetta: _etichettaStato(exam),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      ExamDetailScreen(exam: exam),
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
        backgroundColor: AppColors.exams,
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ExamFormScreen()),
        ),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── Card esame ───────────────────────────────────────────────

class _ExamCard extends StatelessWidget {
  final Exam exam;
  final Color colore;
  final String etichetta;
  final VoidCallback onTap;

  const _ExamCard({
    required this.exam,
    required this.colore,
    required this.etichetta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PlannerProvider>();
    final corso = provider.getCourseById(exam.courseId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Barra laterale colorata
              Container(
                width: 4,
                height: 70,
                decoration: BoxDecoration(
                  color: colore,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.titolo,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (corso != null)
                      Text(
                        corso.nome,
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 13),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          '${exam.data.day}/${exam.data.month}/${exam.data.year}',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                        const SizedBox(width: 10),
                        _Chip(
                            label: exam.tipologia,
                            color: AppColors.exams),
                        const SizedBox(width: 6),
                        _Chip(
                          label: exam.priorita,
                          color: AppColors.priorita(exam.priorita),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _Chip(label: etichetta, color: colore),
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
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600)),
    );
  }
}