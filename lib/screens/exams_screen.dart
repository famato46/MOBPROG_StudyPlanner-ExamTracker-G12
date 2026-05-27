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
          Icon(Icons.assignment, size: 20,
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

  // Colore in base allo stato temporale/effettivo
  Color _coloreEsame(Exam e) {
    if (e.stato == 'completato') return AppColors.success;
    if (e.stato == 'annullato') return AppColors.textMuted;
    if (e.isImminente) return AppColors.danger;
    return AppColors.exams;
  }

  String _etichettaStato(Exam e) {
    if (e.stato == 'completato') return 'Completato';
    if (e.stato == 'annullato') return 'Annullato';
    if (e.isImminente) return 'Imminente';
    if (e.isPassato) return 'Passato (Non svolto)';
    return 'Programmato';
  }

  // Filtra la lista passata in base alla sola tipologia selezionata e applica l'ordinamento
  List<Exam> _processExamsList(List<Exam> baseExams) {
    var filtered = baseExams.where((e) {
      return _filterTipologia == 'tutti' || e.tipologia.toLowerCase() == _filterTipologia;
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

  // Widget helper per generare le liste dentro i singoli Tab
  Widget _buildTabList(List<Exam> typedExams, PlannerProvider provider) {
    final listToShow = _processExamsList(typedExams);

    if (listToShow.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.folder_open, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(
              'Nessun elemento trovato in questa sezione.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: listToShow.length,
      itemBuilder: (context, index) {
        final exam = listToShow[index];
        final colore = _coloreEsame(exam);

        return Dismissible(
          key: ValueKey(exam.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            margin: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.danger,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Elimina elemento'),
                content: Text('Eliminare "${exam.titolo}"?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Annulla'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Elimina', style: TextStyle(color: AppColors.danger)),
                  ),
                ],
              ),
            );
          },
          onDismissed: (_) async {
            await provider.deleteExam(exam.id);
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${exam.titolo} eliminato')),
            );
          },
          child: _ExamCard(
            exam: exam,
            colore: colore,
            etichetta: _etichettaStato(exam),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ExamDetailScreen(exam: exam),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // I 3 stati temporali richiesti dalla traccia
      child: Scaffold(
        appBar: AppBar(
          title: _buildTitleBadge(context),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.sort),
              onSelected: (val) => setState(() => _sortBy = val),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'data', child: Text('Ordina per data')),
                PopupMenuItem(value: 'priorita', child: Text('Ordina per priorità')),
              ],
            ),
          ],
          // Aggiungiamo la TabBar in fondo all'appBar per dividere gli stati temporali
          bottom: TabBar(
            labelColor: AppColors.examsDark,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.exams,
            tabs: const [
              Tab(text: 'In Programma'),
              Tab(text: 'Completati'),
              Tab(text: 'Annullati'),
            ],
          ),
        ),
        body: Consumer<PlannerProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            // Dividiamo a monte gli esami presi dal provider nei 3 gruppi temporali
            final completati = provider.exams.where((e) => e.stato == 'completato').toList();
            final annullati = provider.exams.where((e) => e.stato == 'annullato').toList();
            final programmati = provider.exams.where((e) => e.stato != 'completato' && e.stato != 'annullato').toList();

            return Column(
              children: [
                // Teniamo la riga orizzontale dei FilterChip SOLO per filtrare la Tipologia (Esame, Progetto, ecc.)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Row(
                    children: [
                      ('tutti', 'Tutti i tipi'),
                      ('esame', 'Esami'),
                      ('appello', 'Appelli'),
                      ('consegna', 'Consegne'),
                      ('progetto', 'Progetti'),
                    ].map((entry) {
                      final selected = _filterTipologia == entry.$1;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(entry.$2),
                          selected: selected,
                          selectedColor: AppColors.exams.withOpacity(0.2),
                          checkmarkColor: AppColors.examsDark,
                          onSelected: (_) => setState(() => _filterTipologia = entry.$1),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                // La vista che si adatta dinamicamente in base al Tab selezionato
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildTabList(programmati, provider),
                      _buildTabList(completati, provider),
                      _buildTabList(annullati, provider),
                    ],
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
      ),
    );
  }
}

// ─── Card esame modificata con icone dinamiche per tipologia ───────────────────────────────────────────────

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

  // Metodo per assegnare l'icona più appropriata in base al tipo (Molto apprezzato nella UX del progetto)
  IconData _getIconaTipologia(String tipologia) {
    switch (tipologia.toLowerCase()) {
      case 'esame':
        return Icons.school;
      case 'appello':
        return Icons.rate_review;
      case 'consegna':
        return Icons.alarm;
      case 'progetto':
        return Icons.analytics;
      default:
        return Icons.assignment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<PlannerProvider>();
    final corso = provider.getCourseById(exam.courseId);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Sostituita la barra statica con l'icona dinamica colorata in base allo stato
              CircleAvatar(
                radius: 22,
                backgroundColor: colore.withOpacity(0.15),
                child: Icon(
                  _getIconaTipologia(exam.tipologia),
                  color: colore,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exam.titolo,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    if (corso != null)
                      Text(
                        corso.nome,
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${exam.data.day}/${exam.data.month}/${exam.data.year}',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                            ),
                          ],
                        ),
                        _Chip(label: exam.priorita, color: AppColors.priorita(exam.priorita)),
                        _Chip(label: etichetta, color: colore),
                        if (exam.stato == 'completato' && exam.voto != null)
                          _Chip(label: 'Voto: ${exam.voto}', color: AppColors.success),
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
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}