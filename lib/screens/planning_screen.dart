import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../providers/planner_provider.dart';
import '../models/task.dart';
import '../models/study_session.dart';
import '../models/course.dart';

/// PlanningScreen — "Pianifica" in stile Apple moderno, coerente con
/// le altre schermate (large title, segmented control iOS, card pulite).
///
/// Tre sotto-viste tramite segmented control iOS (non più TabBar Material):
///  1. Oggi          — impegni di oggi
///  2. Pianificatore — calendario giorno/settimana + filtri + CRUD sessioni
///  3. Focus         — timer Pomodoro
///
/// Pattern del prof rispettati:
///  - setState per stato effimero (tab attiva, timer, filtri)
///  - Provider per App State (sessioni, task, corsi)
///  - Timer.periodic + dispose() per il countdown
class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen> {
  // 0 = Oggi, 1 = Pianificatore, 2 = Focus
  int _currentSegment = 0;

  DateTime _giornoPianificatore = DateTime.now();

  // Filtri Tab Pianificatore (stato effimero)
  Course? _filtroCorso;
  String _filtroTipoAttivita = 'Tutti';
  bool _isVistaSettimanale = false;
  bool _filtriEspansi = false;

  // Stato Timer Pomodoro (stato effimero)
  Timer? _pomodoroTimer;
  int _secondsRemaining = 25 * 60;
  bool _isTimerRunning = false;
  Task? _selectedTaskForPomodoro;

  static const int _pomodoroTotal = 25 * 60;

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    super.dispose();
  }

  void _onSegmentChanged(int index) {
    // Uscendo dal Focus, mettiamo in pausa il timer (come prima).
    if (index != 2 && _isTimerRunning) _pausePomodoro();
    setState(() => _currentSegment = index);
  }

  // ─────────────────────────── TIMER ───────────────────────────
  void _startPomodoro() {
    if (_selectedTaskForPomodoro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Seleziona un obiettivo prima di avviare il timer!')),
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
    setState(() => _secondsRemaining = _pomodoroTotal);
  }

  Future<void> _completaPomodoro() async {
    _pomodoroTimer?.cancel();
    if (_selectedTaskForPomodoro != null) {
      await Provider.of<PlannerProvider>(context, listen: false)
          .savePomodoroSession(
        titolo: 'Focus: ${_selectedTaskForPomodoro!.titolo}',
        courseId: _selectedTaskForPomodoro!.courseId,
        examId: _selectedTaskForPomodoro!.examId,
        taskId: _selectedTaskForPomodoro!.id,
        durataEffettiva: 25,
      );
    }
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = _pomodoroTotal;
    });
    if (mounted) _mostraDialogSuccesso();
  }

  void _mostraDialogSuccesso() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Ottimo lavoro!'),
        content: const Text(
            'I tuoi 25 minuti di focus sono stati registrati con successo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Avanti'),
          )
        ],
      ),
    );
  }

  // ─────────────────────────── HELPER ───────────────────────────
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

  // _isSameWeek pulito: inizio settimana (lunedì 00:00) → lunedì successivo.
  bool _isSameWeek(DateTime date, DateTime reference) {
    final inizioSettimana =
        DateTime(reference.year, reference.month, reference.day)
            .subtract(Duration(days: reference.weekday - 1));
    final fineSettimana = inizioSettimana.add(const Duration(days: 7));
    return !date.isBefore(inizioSettimana) &&
        date.isBefore(fineSettimana);
  }

  String _formatGiornoPianificatore() {
    if (_isVistaSettimanale) {
      final inizio = _giornoPianificatore
          .subtract(Duration(days: _giornoPianificatore.weekday - 1));
      return 'Settimana del ${DateFormat('dd MMMM', 'it_IT').format(inizio)}';
    }
    return DateFormat('EEEE dd MMMM', 'it_IT')
        .format(_giornoPianificatore);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? Theme.of(context).colorScheme.surface : AppColors.background;
    final provider = Provider.of<PlannerProvider>(context);
    final oggi = DateTime.now();

    // ===== DATI TAB OGGI =====
    final sessioniOggi = provider.studySessions
        .where((s) => DateUtils.isSameDay(s.data, oggi))
        .toList()
      ..sort((a, b) => a.data.compareTo(b.data));
    final taskOggi = provider.tasks
        .where((t) =>
            t.scadenza != null && DateUtils.isSameDay(t.scadenza, oggi))
        .toList()
      ..sort((a, b) =>
          _pesoPriorita(b.priorita).compareTo(_pesoPriorita(a.priorita)));

    // ===== DATI TAB PIANIFICATORE =====
    var sessioniPianificatore = provider.studySessions.where((s) {
      return _isVistaSettimanale
          ? _isSameWeek(s.data, _giornoPianificatore)
          : DateUtils.isSameDay(s.data, _giornoPianificatore);
    }).toList()
      ..sort((a, b) => a.data.compareTo(b.data));

    if (_filtroCorso != null) {
      sessioniPianificatore = sessioniPianificatore
          .where((s) => s.courseId == _filtroCorso!.id)
          .toList();
    }
    if (_filtroTipoAttivita != 'Tutti') {
      sessioniPianificatore = sessioniPianificatore
          .where((s) =>
              s.tipo.toLowerCase() == _filtroTipoAttivita.toLowerCase())
          .toList();
    }

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            // ── Large title + segmented control ──
            _Header(isDark: isDark),
            const SizedBox(height: 8),
            _SegmentedControl(
              current: _currentSegment,
              onChanged: _onSegmentChanged,
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            // ── Contenuto della vista selezionata ──
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : IndexedStack(
                      index: _currentSegment,
                      children: [
                        _buildTabOggi(sessioniOggi, taskOggi, provider),
                        _buildTabPianificatore(
                            sessioniPianificatore, provider),
                        _buildTabPomodoro(provider.getPendingTasks()),
                      ],
                    ),
            ),
          ],
        ),
      ),
      // FAB "Pianifica" solo nella vista Pianificatore.
      // heroTag univoco per non collidere con gli altri FAB dell'IndexedStack.
      floatingActionButton: _currentSegment == 1
          ? FloatingActionButton.extended(
              heroTag: 'fab_planning',
              backgroundColor: AppColors.planning,
              foregroundColor: Colors.white,
              elevation: 0,
              onPressed: () => _apriDialogPianificazione(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Pianifica',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            )
          : null,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 1 — OGGI
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabOggi(
      List<StudySession> sessioni, List<Task> task, PlannerProvider provider) {
    if (sessioni.isEmpty && task.isEmpty) {
      return _EmptyState(
        icon: Icons.wb_sunny_outlined,
        text: 'Libero! Nessuna attività prevista per oggi.',
      );
    }

    final taskInCorso = task.where((t) => !t.completata).toList();
    final taskCompletati = task.where((t) => t.completata).toList();
    final sessioniInCorso = sessioni.where((s) => !s.completata).toList();
    final sessioniCompletate = sessioni.where((s) => s.completata).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        if (taskInCorso.isNotEmpty || sessioniInCorso.isNotEmpty) ...[
          _SectionLabel(label: 'Da completare oggi', isDark: isDark),
          const SizedBox(height: 8),
          _CardGroup(
            isDark: isDark,
            children: [
              ...taskInCorso.map((t) => _TaskRow(
                    task: t,
                    sottotitolo:
                        provider.getCourseById(t.courseId ?? '')?.nome ??
                            'Generico',
                    onToggle: () => provider.toggleTaskCompletion(t.id),
                    isDark: isDark,
                  )),
              ...sessioniInCorso.map((s) => _SessionRow(
                    session: s,
                    sottotitolo:
                        '${provider.getCourseById(s.courseId ?? '')?.nome ?? "Generico"} · ${s.tipo}',
                    onToggle: () => provider.updateStudySession(
                        s.copyWith(completata: !s.completata)),
                    onEdit: () => _apriDialogPianificazione(context,
                        sessioneEsistente: s),
                    isDark: isDark,
                  )),
            ],
          ),
          const SizedBox(height: 24),
        ],
        if (taskCompletati.isNotEmpty || sessioniCompletate.isNotEmpty) ...[
          _SectionLabel(
              label: 'Completate',
              isDark: isDark,
              color: AppColors.success),
          const SizedBox(height: 8),
          _CardGroup(
            isDark: isDark,
            children: [
              ...taskCompletati.map((t) => _TaskRow(
                    task: t,
                    sottotitolo:
                        provider.getCourseById(t.courseId ?? '')?.nome ??
                            'Generico',
                    onToggle: () => provider.toggleTaskCompletion(t.id),
                    isDark: isDark,
                  )),
              ...sessioniCompletate.map((s) => _SessionRow(
                    session: s,
                    sottotitolo:
                        '${provider.getCourseById(s.courseId ?? '')?.nome ?? "Generico"} · ${s.tipo}',
                    onToggle: () => provider.updateStudySession(
                        s.copyWith(completata: !s.completata)),
                    onEdit: () => _apriDialogPianificazione(context,
                        sessioneEsistente: s),
                    isDark: isDark,
                  )),
            ],
          ),
        ],
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 2 — PIANIFICATORE
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabPianificatore(
      List<StudySession> sessioni, PlannerProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sessioniInCorso = sessioni.where((s) => !s.completata).toList();
    final sessioniCompletate = sessioni.where((s) => s.completata).toList();
    final filtriAttivi =
        _filtroCorso != null || _filtroTipoAttivita != 'Tutti';

    return Column(
      children: [
        // ── Toggle Giornaliera/Settimanale + Scegli Data ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            children: [
              _MiniSegment(
                options: const ['Giornaliera', 'Settimanale'],
                selectedIndex: _isVistaSettimanale ? 1 : 0,
                onChanged: (i) =>
                    setState(() => _isVistaSettimanale = i == 1),
                isDark: isDark,
              ),
              const Spacer(),
              _PillButton(
                icon: Icons.calendar_today_rounded,
                label: 'Data',
                onTap: () async {
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
                isDark: isDark,
              ),
            ],
          ),
        ),

        // ── Data corrente ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            children: [
              Icon(Icons.event_rounded,
                  size: 20, color: AppColors.planningDeep),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formatGiornoPianificatore(),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Filtri (espandibili) ──
        _FilterSection(
          espanso: _filtriEspansi,
          filtriAttivi: filtriAttivi,
          onToggle: () => setState(() => _filtriEspansi = !_filtriEspansi),
          onReset: () => setState(() {
            _filtroCorso = null;
            _filtroTipoAttivita = 'Tutti';
          }),
          corsi: provider.courses,
          filtroCorso: _filtroCorso,
          filtroTipo: _filtroTipoAttivita,
          onCorsoChanged: (c) => setState(() => _filtroCorso = c),
          onTipoChanged: (t) => setState(() => _filtroTipoAttivita = t),
          isDark: isDark,
        ),

        const SizedBox(height: 8),

        // ── Lista sessioni ──
        Expanded(
          child: sessioni.isEmpty
              ? _EmptyState(
                  icon: Icons.event_busy_outlined,
                  text: 'Nessun impegno corrisponde ai criteri.',
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                  children: [
                    if (sessioniInCorso.isNotEmpty)
                      _CardGroup(
                        isDark: isDark,
                        children: sessioniInCorso
                            .map((s) => _SessionRow(
                                  session: s,
                                  sottotitolo: _sottotitoloSessione(
                                      s, provider),
                                  onToggle: () =>
                                      provider.updateStudySession(s.copyWith(
                                          completata: !s.completata)),
                                  onEdit: () => _apriDialogPianificazione(
                                      context,
                                      sessioneEsistente: s),
                                  onDelete: () async {
                                    final c = await _confirmDeleteSessione(
                                        context, s);
                                    if (c == true && context.mounted) {
                                      await provider.deleteStudySession(s.id);
                                    }
                                  },
                                  isDark: isDark,
                                ))
                            .toList(),
                      ),
                    if (sessioniCompletate.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _SectionLabel(
                          label: 'Completate',
                          isDark: isDark,
                          color: AppColors.success),
                      const SizedBox(height: 8),
                      _CardGroup(
                        isDark: isDark,
                        children: sessioniCompletate
                            .map((s) => _SessionRow(
                                  session: s,
                                  sottotitolo: _sottotitoloSessione(
                                      s, provider),
                                  onToggle: () =>
                                      provider.updateStudySession(s.copyWith(
                                          completata: !s.completata)),
                                  onEdit: () => _apriDialogPianificazione(
                                      context,
                                      sessioneEsistente: s),
                                  onDelete: () async {
                                    final c = await _confirmDeleteSessione(
                                        context, s);
                                    if (c == true && context.mounted) {
                                      await provider.deleteStudySession(s.id);
                                    }
                                  },
                                  isDark: isDark,
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  String _sottotitoloSessione(StudySession s, PlannerProvider provider) {
    final prefisso = _isVistaSettimanale
        ? '${DateFormat('EE dd/MM', 'it_IT').format(s.data)} · '
        : '';
    final corso =
        provider.getCourseById(s.courseId ?? '')?.nome ?? 'Generico';
    return '$prefisso$corso · ${s.tipo}';
  }

  Future<bool?> _confirmDeleteSessione(
      BuildContext context, StudySession s) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina sessione'),
        content: Text('Eliminare "${s.titolo}"?'),
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

  // ═══════════════════════════════════════════════════════════════
  // TAB 3 — FOCUS POMODORO
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabPomodoro(List<Task> pendingTasks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _secondsRemaining / _pomodoroTotal;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          // ── Selettore obiettivo (card iOS) ──
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Task>(
                isExpanded: true,
                value: _selectedTaskForPomodoro,
                hint: Text(
                  'Seleziona l\'obiettivo su cui concentrarti',
                  style: TextStyle(
                      fontSize: 15, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
                icon: Icon(Icons.unfold_more_rounded,
                    color: AppColors.textMuted, size: 20),
                items: pendingTasks
                    .map((t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.titolo,
                              overflow: TextOverflow.ellipsis),
                        ))
                    .toList(),
                onChanged: _isTimerRunning
                    ? null
                    : (task) =>
                        setState(() => _selectedTaskForPomodoro = task),
              ),
            ),
          ),
          const SizedBox(height: 48),

          // ── Cerchio timer ──
          SizedBox(
            width: 240,
            height: 240,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 240,
                  height: 240,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 8,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : AppColors.planning.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.planningDeep),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 52,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark ? Colors.white : AppColors.textPrimary,
                        letterSpacing: -1,
                      ),
                    ),
                    Text(
                      _isTimerRunning ? 'In corso' : 'Pronto',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 48),

          // ── Controlli ──
          Row(
            children: [
              if (!_isTimerRunning && _secondsRemaining < _pomodoroTotal) ...[
                _CircleControl(
                  icon: Icons.refresh_rounded,
                  onTap: _resetPomodoro,
                  isDark: isDark,
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: GestureDetector(
                  onTap: _isTimerRunning ? _pausePomodoro : _startPomodoro,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isTimerRunning
                          ? AppColors.warning
                          : AppColors.planningDeep,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _isTimerRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isTimerRunning ? 'Pausa' : 'Inizia Focus',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // DIALOG PIANIFICAZIONE (invariato nella logica)
  // ═══════════════════════════════════════════════════════════════
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
          content:
              Text('Inserisci prima un Corso nell\'apposita schermata!')));
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
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
                const SizedBox(height: 12),
                DropdownButtonFormField<Course>(
                  decoration: const InputDecoration(labelText: 'Corso *'),
                  initialValue: corsoScelto,
                  items: provider.courses
                      .map((c) =>
                          DropdownMenuItem(value: c, child: Text(c.nome)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => corsoScelto = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration:
                      const InputDecoration(labelText: 'Tipo Attività'),
                  initialValue: tipoStudio,
                  items: const [
                    'Studio',
                    'Ripasso',
                    'Esercitazione',
                    'Progetto',
                    'Consegna'
                  ]
                      .map((e) =>
                          DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => tipoStudio = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.planning,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (titController.text.trim().isEmpty ||
                    corsoScelto == null) {
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

// ═══════════════════════════════════════════════════════════════
// HEADER — large title iOS
// ═══════════════════════════════════════════════════════════════
class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pianifica',
              style: TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                height: 1.05,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Organizza studio e sessioni di focus',
              style: TextStyle(
                fontSize: 15,
                color: isDark
                    ? Colors.white70
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SEGMENTED CONTROL principale (Oggi / Pianificatore / Focus)
// ═══════════════════════════════════════════════════════════════
class _SegmentedControl extends StatelessWidget {
  final int current;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _SegmentedControl({
    required this.current,
    required this.onChanged,
    required this.isDark,
  });

  static const _labels = ['Oggi', 'Pianificatore', 'Focus'];
  static const _icons = [
    Icons.today_rounded,
    Icons.calendar_month_rounded,
    Icons.timer_outlined,
  ];

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
        child: Row(
          children: List.generate(3, (i) {
            final selected = i == current;
            return Expanded(
              child: GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.planning
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _icons[i],
                        size: 18,
                        color: selected
                            ? Colors.white
                            : (isDark
                                ? Colors.white70
                                : AppColors.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _labels[i],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : (isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MINI SEGMENT (Giornaliera / Settimanale)
// ═══════════════════════════════════════════════════════════════
class _MiniSegment extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;

  const _MiniSegment({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final selected = i == selectedIndex;
          return GestureDetector(
            onTap: () => onChanged(i),
            behavior: HitTestBehavior.opaque,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected
                    ? (isDark ? const Color(0xFF3A3A3C) : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                options[i],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected
                      ? (isDark ? Colors.white : AppColors.textPrimary)
                      : AppColors.textMuted,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PILL BUTTON ("Data")
// ═══════════════════════════════════════════════════════════════
class _PillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _PillButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.planningDeep),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// FILTER SECTION (espandibile)
// ═══════════════════════════════════════════════════════════════
class _FilterSection extends StatelessWidget {
  final bool espanso;
  final bool filtriAttivi;
  final VoidCallback onToggle;
  final VoidCallback onReset;
  final List<Course> corsi;
  final Course? filtroCorso;
  final String filtroTipo;
  final ValueChanged<Course?> onCorsoChanged;
  final ValueChanged<String> onTipoChanged;
  final bool isDark;

  const _FilterSection({
    required this.espanso,
    required this.filtriAttivi,
    required this.onToggle,
    required this.onReset,
    required this.corsi,
    required this.filtroCorso,
    required this.filtroTipo,
    required this.onCorsoChanged,
    required this.onTipoChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          // Riga header del filtro
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.filter_list_rounded,
                        size: 18, color: AppColors.planningDeep),
                    const SizedBox(width: 8),
                    Text(
                      'Filtra attività',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? Colors.white
                            : AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    if (filtriAttivi)
                      GestureDetector(
                        onTap: onReset,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            'Reset',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.danger,
                            ),
                          ),
                        ),
                      ),
                    Icon(
                      espanso
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Corpo espandibile
          if (espanso)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<Course?>(
                      decoration: InputDecoration(
                        labelText: 'Corso',
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      initialValue: filtroCorso,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<Course?>(
                            value: null,
                            child: Text('Tutti i Corsi')),
                        ...corsi.map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.nome,
                                overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: onCorsoChanged,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Tipo',
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 8),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      initialValue: filtroTipo,
                      isExpanded: true,
                      items: const [
                        'Tutti',
                        'Studio',
                        'Ripasso',
                        'Esercitazione',
                        'Progetto',
                        'Consegna'
                      ]
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => onTipoChanged(v!),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION LABEL
// ═══════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  final String label;
  final bool isDark;
  final Color? color;

  const _SectionLabel({
    required this.label,
    required this.isDark,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color ??
              (isDark ? Colors.white : AppColors.textPrimary),
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// CARD GROUP (contenitore lista bianco con divider)
// ═══════════════════════════════════════════════════════════════
class _CardGroup extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _CardGroup({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
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
          padding: const EdgeInsets.only(left: 50),
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
// TASK ROW
// ═══════════════════════════════════════════════════════════════
class _TaskRow extends StatelessWidget {
  final Task task;
  final String sottotitolo;
  final VoidCallback onToggle;
  final bool isDark;

  const _TaskRow({
    required this.task,
    required this.sottotitolo,
    required this.onToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppColors.priorita(task.priorita);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.completata
                    ? AppColors.iosBlue
                    : Colors.transparent,
                border: Border.all(
                  color: task.completata
                      ? AppColors.iosBlue
                      : (isDark ? Colors.white38 : AppColors.textMuted),
                  width: 2,
                ),
              ),
              child: task.completata
                  ? const Icon(Icons.check_rounded,
                      size: 15, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.titolo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    decoration: task.completata
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: AppColors.textMuted,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sottotitolo,
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
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
  }
}

// ═══════════════════════════════════════════════════════════════
// SESSION ROW (con toggle, edit, swipe-delete)
// ═══════════════════════════════════════════════════════════════
class _SessionRow extends StatelessWidget {
  final StudySession session;
  final String sottotitolo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final Future<void> Function()? onDelete;
  final bool isDark;

  const _SessionRow({
    required this.session,
    required this.sottotitolo,
    required this.onToggle,
    required this.onEdit,
    this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isConsegna = session.tipo.toLowerCase() == 'consegna';

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: session.completata
                    ? AppColors.success
                    : Colors.transparent,
                border: Border.all(
                  color: session.completata
                      ? AppColors.success
                      : (isDark ? Colors.white38 : AppColors.textMuted),
                  width: 2,
                ),
              ),
              child: session.completata
                  ? const Icon(Icons.check_rounded,
                      size: 15, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            isConsegna
                ? Icons.assignment_turned_in_outlined
                : Icons.menu_book_rounded,
            size: 18,
            color: isConsegna ? AppColors.danger : AppColors.planningDeep,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.titolo,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    decoration: session.completata
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: AppColors.textMuted,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sottotitolo,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? Colors.white60
                        : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.edit_outlined,
                  size: 18, color: AppColors.iosBlue),
            ),
          ),
        ],
      ),
    );

    if (onDelete != null) {
      return Dismissible(
        key: ValueKey('session_${session.id}'),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: AppColors.danger,
          child: const Icon(Icons.delete_rounded, color: Colors.white),
        ),
        confirmDismiss: (_) async {
          await onDelete!();
          return false;
        },
        child: content,
      );
    }
    return content;
  }
}

// ═══════════════════════════════════════════════════════════════
// CIRCLE CONTROL (reset timer)
// ═══════════════════════════════════════════════════════════════
class _CircleControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;

  const _CircleControl({
    required this.icon,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.surface,
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : AppColors.border,
          ),
        ),
        child: Icon(icon,
            color: isDark ? Colors.white : AppColors.textPrimary),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// EMPTY STATE
// ═══════════════════════════════════════════════════════════════
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const _EmptyState({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}