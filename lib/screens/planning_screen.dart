import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../providers/planner_provider.dart';
import '../models/task.dart';
import '../models/study_session.dart';
import '../models/course.dart';

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTime _giornoPianificatore = DateTime.now();

  // Stati locali per i Filtri della Tab 2 (Pianificatore)
  Course? _filtroCorso;
  String _filtroTipoAttivita = 'Tutti';
  bool _isVistaSettimanale = false;

  // Stato Timer Pomodoro (Tab 3)
  Timer? _pomodoroTimer;
  int _secondsRemaining = 25 * 60;
  bool _isTimerRunning = false;
  Task? _selectedTaskForPomodoro;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _tabController.index != 2) {
        _pausePomodoro();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  // --- LOGICA TIMER POMODORO ---
  void _startPomodoro() {
    if (_selectedTaskForPomodoro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Seleziona un obiettivo prima di avviare il timer!')),
      );
      return;
    }
    setState(() => _isTimerRunning = true);
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _completaPomodoro();
      }
    });
  }

  void _pausePomodoro() {
    _pomodoroTimer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  void _resetPomodoro() {
    _pausePomodoro();
    setState(() => _secondsRemaining = 25 * 60);
  }

  Future<void> _completaPomodoro() async {
    _pomodoroTimer?.cancel();
    if (_selectedTaskForPomodoro != null) {
      await Provider.of<PlannerProvider>(context, listen: false)
          .savePomodoroSession(
        titolo: '🍅 Focus: ${_selectedTaskForPomodoro!.titolo}',
        courseId: _selectedTaskForPomodoro!.courseId,
        examId: _selectedTaskForPomodoro!.examId,
        taskId: _selectedTaskForPomodoro!.id,
        durataEffettiva: 25,
      );
    }
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = 25 * 60;
    });
    _mostraDialogSuccesso();
  }

  void _mostraDialogSuccesso() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ottimo lavoro!'),
        content: const Text(
            'I tuoi 25 minuti di focus sono stati registrati con successo.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Avanti'))
        ],
      ),
    );
  }

  int _pesoPriorita(String priorita) {
    switch (priorita.toLowerCase()) {
      case 'alta':
        return 3;
      case 'media':
        return 2;
      case 'bassa':
        return 1;
      default:
        return 0;
    }
  }

  Color _colorePriorita(String priorita) {
    switch (priorita.toLowerCase()) {
      case 'alta':
        return Colors.redAccent;
      case 'media':
        return Colors.orangeAccent;
      case 'bassa':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Widget badge priorità (solo per i Task)
  Widget _buildPriorityBadge(String priorita) {
    final colore = _colorePriorita(priorita);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        // FIX problema 3: withOpacity → withValues(alpha:)
        color: colore.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: colore, width: 1),
      ),
      child: Text(
        priorita.toUpperCase(),
        style: TextStyle(
            color: colore, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  // FIX problema 5: _isSameWeek pulito e corretto.
  // Calcoliamo l'inizio della settimana (lunedì 00:00) e la fine (lunedì successivo 00:00)
  // poi controlliamo se `date` cade in [inizio, fine).
  bool _isSameWeek(DateTime date, DateTime reference) {
    final inizioSettimana = DateTime(
            reference.year, reference.month, reference.day)
        .subtract(Duration(days: reference.weekday - 1));
    final fineSettimana = inizioSettimana.add(const Duration(days: 7));
    return !date.isBefore(inizioSettimana) && date.isBefore(fineSettimana);
  }

  // Helper per formatazione date in italiano (FIX problema 6)
  String _formatGiornoPianificatore() {
    if (_isVistaSettimanale) {
      final inizio = _giornoPianificatore
          .subtract(Duration(days: _giornoPianificatore.weekday - 1));
      return 'Settimana del ${DateFormat('dd MMMM', 'it_IT').format(inizio)}';
    }
    return DateFormat('EEEE dd MMMM', 'it_IT').format(_giornoPianificatore);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlannerProvider>(context);
    final oggi = DateTime.now();

    // ================= DATI TAB 1 (OGGI) =================
    final sessioniOggi = provider.studySessions
        .where((s) => DateUtils.isSameDay(s.data, oggi))
        .toList();
    final taskOggi = provider.tasks
        .where((t) =>
            t.scadenza != null && DateUtils.isSameDay(t.scadenza, oggi))
        .toList();

    taskOggi.sort(
        (a, b) => _pesoPriorita(b.priorita).compareTo(_pesoPriorita(a.priorita)));
    sessioniOggi.sort((a, b) => a.data.compareTo(b.data));

    // ================= DATI TAB 2 (PIANIFICATORE + FILTRI + VISTA) =================
    var sessioniPianificatore = provider.studySessions.where((s) {
      if (_isVistaSettimanale) {
        return _isSameWeek(s.data, _giornoPianificatore);
      } else {
        return DateUtils.isSameDay(s.data, _giornoPianificatore);
      }
    }).toList();

    sessioniPianificatore.sort((a, b) => a.data.compareTo(b.data));

    if (_filtroCorso != null) {
      sessioniPianificatore = sessioniPianificatore
          .where((s) => s.courseId == _filtroCorso!.id)
          .toList();
    }
    if (_filtroTipoAttivita != 'Tutti') {
      sessioniPianificatore = sessioniPianificatore
          .where(
              (s) => s.tipo.toLowerCase() == _filtroTipoAttivita.toLowerCase())
          .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Planning & Focus',
            style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.planning,
          tabs: const [
            Tab(icon: Icon(Icons.today), text: 'Oggi'),
            Tab(icon: Icon(Icons.calendar_month), text: 'Pianificatore'),
            Tab(icon: Icon(Icons.timer), text: 'Focus Pomodoro'),
          ],
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTabOggi(sessioniOggi, taskOggi, provider),
                _buildTabPianificatore(sessioniPianificatore, provider),
                _buildTabPomodoro(provider.getPendingTasks()),
              ],
            ),
      floatingActionButton: _tabController.index == 1
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.planning,
              onPressed: () => _apriDialogPianificazione(context),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Pianifica',
                  style: TextStyle(color: Colors.white)),
            )
          : null,
    );
  }

  // --- TAB 1: OGGI ---
  Widget _buildTabOggi(
      List<StudySession> sessioni, List<Task> task, PlannerProvider provider) {
    if (sessioni.isEmpty && task.isEmpty) {
      return const Center(
        child: Text('Libero! Nessuna attività prevista per oggi.',
            style: TextStyle(color: Colors.grey)),
      );
    }
    final taskInCorso = task.where((t) => !t.completata).toList();
    final taskCompletati = task.where((t) => t.completata).toList();
    final sessioniInCorso = sessioni.where((s) => !s.completata).toList();
    final sessioniCompletate = sessioni.where((s) => s.completata).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (taskInCorso.isNotEmpty || sessioniInCorso.isNotEmpty) ...[
          Text('Da Completare Oggi',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 8),
          ...taskInCorso.map((t) => _buildTaskCard(t, provider)),
          ...sessioniInCorso.map((s) => _buildSessionCard(s, provider)),
          const SizedBox(height: 24),
        ],
        if (taskCompletati.isNotEmpty || sessioniCompletate.isNotEmpty) ...[
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text('Attività Completate',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(height: 8),
          ...taskCompletati
              .map((t) => Opacity(opacity: 0.6, child: _buildTaskCard(t, provider))),
          ...sessioniCompletate.map(
              (s) => Opacity(opacity: 0.6, child: _buildSessionCard(s, provider))),
        ],
      ],
    );
  }

  Widget _buildTaskCard(Task t, PlannerProvider provider) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: Checkbox(
          // NOTA: su CheckboxListTile/Checkbox, `value:` NON è deprecato.
          // Solo nei DropdownButtonFormField va sostituito con initialValue.
          value: t.completata,
          onChanged: (_) => provider.toggleTaskCompletion(t.id),
        ),
        title: Text(t.titolo,
            style: TextStyle(
                decoration:
                    t.completata ? TextDecoration.lineThrough : null)),
        subtitle: Text(
            provider.getCourseById(t.courseId ?? '')?.nome ?? 'Generico'),
        trailing: _buildPriorityBadge(t.priorita),
      ),
    );
  }

  Widget _buildSessionCard(StudySession s, PlannerProvider provider,
      {bool mostraData = false}) {
    String dataString = mostraData
        ? '${DateFormat('dd/MM', 'it_IT').format(s.data)} • '
        : '';
    return Card(
      child: ListTile(
        leading: Icon(
            s.tipo.toLowerCase() == 'consegna'
                ? Icons.assignment_turned_in
                : Icons.menu_book,
            color: s.tipo.toLowerCase() == 'consegna'
                ? Colors.redAccent
                : AppColors.planning),
        title: Row(
          children: [
            Expanded(
                child: Text(s.titolo,
                    style: TextStyle(
                        decoration: s.completata
                            ? TextDecoration.lineThrough
                            : null))),
            const SizedBox(width: 8),
          ],
        ),
        subtitle: Text(
            '$dataString${provider.getCourseById(s.courseId ?? '')?.nome ?? "Generico"} • ${s.tipo}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined,
                  color: Colors.blueGrey, size: 20),
              onPressed: () =>
                  _apriDialogPianificazione(context, sessioneEsistente: s),
            ),
            Checkbox(
              value: s.completata,
              onChanged: (v) =>
                  provider.updateStudySession(s.copyWith(completata: v!)),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: PIANIFICATORE ---
  Widget _buildTabPianificatore(
      List<StudySession> sessioni, PlannerProvider provider) {
    final sessioniInCorso = sessioni.where((s) => !s.completata).toList();
    final sessioniCompletate = sessioni.where((s) => s.completata).toList();

    return Column(
      children: [
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ToggleButtons(
                borderRadius: BorderRadius.circular(8),
                constraints:
                    const BoxConstraints(minHeight: 36, minWidth: 90),
                isSelected: [!_isVistaSettimanale, _isVistaSettimanale],
                onPressed: (index) {
                  setState(() => _isVistaSettimanale = index == 1);
                },
                children: const [
                  Text('Giornaliera'),
                  Text('Settimanale'),
                ],
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.date_range, size: 16),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _giornoPianificatore,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 30)),
                    lastDate:
                        DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => _giornoPianificatore = picked);
                  }
                },
                label: const Text('Scegli Data'),
              ),
            ],
          ),
        ),
        ListTile(
          title: Text(
            _formatGiornoPianificatore(),
            style:
                const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          leading: Icon(
              _isVistaSettimanale
                  ? Icons.date_range_outlined
                  : Icons.calendar_today,
              color: AppColors.planning),
        ),
        Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
          child: ExpansionTile(
            leading: const Icon(Icons.filter_list, size: 20),
            title: const Text('Filtra attività del periodo',
                style: TextStyle(fontSize: 14)),
            trailing: (_filtroCorso != null || _filtroTipoAttivita != 'Tutti')
                ? TextButton(
                    onPressed: () => setState(() {
                      _filtroCorso = null;
                      _filtroTipoAttivita = 'Tutti';
                    }),
                    child: const Text('Reset',
                        style:
                            TextStyle(color: Colors.red, fontSize: 12)),
                  )
                : null,
            children: [
              Padding(
                padding: const EdgeInsets.only(
                    bottom: 12.0, left: 4.0, right: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<Course?>(
                        decoration: const InputDecoration(
                            labelText: 'Corso',
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10)),
                        // FIX problema 4: value → initialValue
                        initialValue: _filtroCorso,
                        hint: const Text('Tutti'),
                        items: [
                          const DropdownMenuItem<Course?>(
                              value: null, child: Text('Tutti i Corsi')),
                          ...provider.courses.map((c) =>
                              DropdownMenuItem(value: c, child: Text(c.nome)))
                        ],
                        onChanged: (v) => setState(() => _filtroCorso = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                            labelText: 'Tipo',
                            contentPadding:
                                EdgeInsets.symmetric(horizontal: 10)),
                        // FIX problema 4: value → initialValue
                        initialValue: _filtroTipoAttivita,
                        items: [
                          'Tutti',
                          'Studio',
                          'Ripasso',
                          'Esercitazione',
                          'Progetto',
                          'Consegna'
                        ]
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _filtroTipoAttivita = v!),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: sessioni.isEmpty
              ? const Center(
                  child: Text(
                      'Nessun impegno corrisponde ai criteri.',
                      style: TextStyle(color: Colors.grey)))
              : ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    if (sessioniInCorso.isNotEmpty) ...[
                      ...sessioniInCorso
                          .map((s) => _buildPianificatoreCard(s, provider)),
                    ],
                    if (sessioniCompletate.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.0, vertical: 8.0),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                color: Colors.green, size: 16),
                            SizedBox(width: 8),
                            Text('Sessioni Completate',
                                style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13)),
                          ],
                        ),
                      ),
                      ...sessioniCompletate.map((s) => Opacity(
                          opacity: 0.5,
                          child: _buildPianificatoreCard(s, provider))),
                    ],
                  ],
                ),
        )
      ],
    );
  }

  Widget _buildPianificatoreCard(StudySession s, PlannerProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Checkbox(
          value: s.completata,
          onChanged: (v) =>
              provider.updateStudySession(s.copyWith(completata: v!)),
        ),
        title: Row(
          children: [
            Expanded(
                child: Text(s.titolo,
                    style: TextStyle(
                        decoration: s.completata
                            ? TextDecoration.lineThrough
                            : null))),
            const SizedBox(width: 8),
          ],
        ),
        subtitle: Text(
          '${_isVistaSettimanale ? "${DateFormat('EE dd/MM', 'it_IT').format(s.data)} • " : ""}${provider.getCourseById(s.courseId ?? '')?.nome ?? "Generico"} • Tipo: ${s.tipo}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent),
              onPressed: () =>
                  _apriDialogPianificazione(context, sessioneEsistente: s),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () async {
                await provider.deleteStudySession(s.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: POMODORO ---
  Widget _buildTabPomodoro(List<Task> pendingTasks) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButtonFormField<Task>(
            decoration: const InputDecoration(
              labelText: 'Seleziona l\'obiettivo su cui concentrarti',
              border: OutlineInputBorder(),
            ),
            // FIX problema 4: value → initialValue
            initialValue: _selectedTaskForPomodoro,
            items: pendingTasks
                .map((t) => DropdownMenuItem(value: t, child: Text(t.titolo)))
                .toList(),
            onChanged: _isTimerRunning
                ? null
                : (task) =>
                    setState(() => _selectedTaskForPomodoro = task),
          ),
          const Spacer(),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 220,
                height: 220,
                child: CircularProgressIndicator(
                  value: _secondsRemaining / (25 * 60),
                  strokeWidth: 6,
                  backgroundColor: Colors.grey[200],
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.redAccent),
                ),
              ),
              Text(
                '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                style: const TextStyle(
                    fontSize: 48, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FloatingActionButton.extended(
                heroTag: 'btnStart',
                onPressed:
                    _isTimerRunning ? _pausePomodoro : _startPomodoro,
                backgroundColor:
                    _isTimerRunning ? Colors.orange : Colors.green,
                icon: Icon(
                    _isTimerRunning ? Icons.pause : Icons.play_arrow,
                    color: Colors.white),
                label: Text(
                    _isTimerRunning ? 'Pausa' : 'Inizia Focus',
                    style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 16),
              if (!_isTimerRunning && _secondsRemaining < 25 * 60)
                IconButton.filledTonal(
                  onPressed: _resetPomodoro,
                  icon: const Icon(Icons.refresh),
                ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // --- DIALOG UNIFICATO ---
  void _apriDialogPianificazione(BuildContext context,
      {StudySession? sessioneEsistente}) {
    final provider = Provider.of<PlannerProvider>(context, listen: false);
    final isModifica = sessioneEsistente != null;
    final titController = TextEditingController(
        text: isModifica ? sessioneEsistente.titolo : '');
    Course? corsoScelto;
    if (isModifica) {
      try {
        corsoScelto = provider.courses
            .firstWhere((c) => c.id == sessioneEsistente.courseId);
      } catch (_) {
        corsoScelto = null;
      }
    }
    String tipoStudio = isModifica ? sessioneEsistente.tipo : 'Studio';

    if (provider.courses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Inserisci prima un Corso nell\'apposita schermata!')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(isModifica ? 'Modifica Sessione' : 'Pianifica Studio'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titController,
                  decoration: const InputDecoration(
                      labelText: 'Cosa farai? (Titolo) *'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<Course>(
                  decoration: const InputDecoration(labelText: 'Corso *'),
                  // FIX problema 4: value → initialValue
                  initialValue: corsoScelto,
                  items: provider.courses
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.nome)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => corsoScelto = v),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Tipo Attività'),
                  // FIX problema 4: value → initialValue
                  initialValue: tipoStudio,
                  items: [
                    'Studio',
                    'Ripasso',
                    'Esercitazione',
                    'Progetto',
                    'Consegna'
                  ]
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => tipoStudio = v!),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Annulla')),
            ElevatedButton(
              onPressed: () async {
                if (titController.text.trim().isEmpty || corsoScelto == null) {
                  return;
                }
                try {
                  if (isModifica) {
                    final sessioneAggiornata = sessioneEsistente.copyWith(
                      titolo: titController.text.trim(),
                      courseId: corsoScelto!.id,
                      tipo: tipoStudio,
                    );
                    await provider.updateStudySession(sessioneAggiornata);
                  } else {
                    await provider.addStudySession(
                      titolo: titController.text.trim(),
                      courseId: corsoScelto!.id,
                      data: _giornoPianificatore,
                      durataPianificata: 60,
                      tipo: tipoStudio,
                    );
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                } catch (e) {
                  debugPrint('Errore salvataggio sessione: $e');
                }
              },
              child: Text(isModifica ? 'Aggiorna' : 'Salva'),
            )
          ],
        ),
      ),
    );
  }
}