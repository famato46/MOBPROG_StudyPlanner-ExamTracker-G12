import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../utils/app_colors.dart';
import '../providers/planner_provider.dart';
import '../models/task.dart';
import '../models/study_session.dart';
import '../models/course.dart';
import 'task_form_screen.dart';
import 'session_form_screen.dart';

/// Tipo di sessione del timer Focus.
/// Replica il pattern `enum SessionType { pomodoro, pausa }` del prof.
enum FocusType { pomodoro, pausa }

/// PlanningScreen — "Pianifica" in stile Apple moderno.
///
/// Tre sotto-viste tramite segmented control iOS:
///  1. Oggi          — impegni di oggi (sessioni + task) con "+ Attività"
///  2. Pianificatore — calendario giorno/settimana + filtri + CRUD sessioni
///  3. Focus         — timer con Tecnica Pomodoro (Pomodoro / Pausa + reset)
///
/// Pattern del prof rispettati:
///  - setState per stato effimero (tab, timer, filtri)
///  - Provider per App State (sessioni, task, corsi)
///  - Timer.periodic + dispose() per il countdown
///  - enum FocusType per il tipo di sessione (come SessionType del prof)
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

  // ─── Stato Timer Focus (Pomodoro / Pausa) ───
  // Durate (in secondi). Come il prof: due durate diverse.
  static const int _pomodoroSeconds = 25 * 60;
  static const int _pausaSeconds = 5 * 60;

  FocusType _focusType = FocusType.pomodoro;
  Timer? _focusTimer;
  int _secondsRemaining = _pomodoroSeconds;
  bool _isTimerRunning = false;
  Task? _selectedTaskForPomodoro;

  int get _currentTotal =>
      _focusType == FocusType.pomodoro ? _pomodoroSeconds : _pausaSeconds;

  @override
  void dispose() {
    _focusTimer?.cancel();
    super.dispose();
  }

  void _onSegmentChanged(int index) {
    if (index != 2 && _isTimerRunning) _pauseTimer();
    setState(() => _currentSegment = index);
  }

  // ─────────────────────────── TIMER ───────────────────────────
  void _startTimer() {
    // Solo per il Pomodoro serve un obiettivo selezionato; la pausa no.
    if (_focusType == FocusType.pomodoro &&
        _selectedTaskForPomodoro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Seleziona un obiettivo prima di avviare il Pomodoro!')),
      );
      return;
    }
    setState(() => _isTimerRunning = true);
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        _completaSessione();
      }
    });
  }

  void _pauseTimer() {
    _focusTimer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  // Reset: ferma e riporta al valore pieno del tipo corrente.
  void _resetTimer() {
    _focusTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = _currentTotal;
    });
  }

  // Cambia tipo (Pomodoro/Pausa): ferma il timer e resetta i secondi.
  void _switchFocusType(FocusType type) {
    _focusTimer?.cancel();
    setState(() {
      _focusType = type;
      _isTimerRunning = false;
      _secondsRemaining =
          type == FocusType.pomodoro ? _pomodoroSeconds : _pausaSeconds;
    });
  }

  Future<void> _completaSessione() async {
    _focusTimer?.cancel();

    // Salviamo nello storico solo i Pomodoro (lavoro vero), non le pause.
    if (_focusType == FocusType.pomodoro &&
        _selectedTaskForPomodoro != null) {
      await Provider.of<PlannerProvider>(context, listen: false)
          .savePomodoroSession(
        titolo: 'Focus: ${_selectedTaskForPomodoro!.titolo}',
        courseId: _selectedTaskForPomodoro!.courseId,
        examId: _selectedTaskForPomodoro!.examId,
        taskId: _selectedTaskForPomodoro!.id,
        durataEffettiva: _pomodoroSeconds ~/ 60,
      );
    }

    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = _currentTotal;
    });
    if (mounted) _mostraDialogFine();
  }

  void _mostraDialogFine() {
    final isPomodoro = _focusType == FocusType.pomodoro;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(isPomodoro ? 'Pomodoro completato!' : 'Pausa finita!'),
        content: Text(isPomodoro
            ? 'I tuoi 25 minuti di focus sono stati registrati. Fai una pausa!'
            : 'Pronto per un altro Pomodoro?'),
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

  // Apre il form a tutto schermo per creare/modificare una sessione.
  void _apriFormSessione({StudySession? sessione}) {
    final provider = context.read<PlannerProvider>();
    if (provider.courses.isEmpty && sessione == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Inserisci prima un Corso nell\'apposita schermata!')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SessionFormScreen(
          sessione: sessione,
          dataIniziale: _giornoPianificatore,
        ),
      ),
    );
  }

  // Apre il form a tutto schermo per creare/modificare un Task.
  void _apriFormTask({Task? task}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(taskToEdit: task),
      ),
    );
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
            _Header(isDark: isDark),
            const SizedBox(height: 8),
            _SegmentedControl(
              current: _currentSegment,
              onChanged: _onSegmentChanged,
              isDark: isDark,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : IndexedStack(
                      index: _currentSegment,
                      children: [
                        _buildTabOggi(sessioniOggi, taskOggi, provider),
                        _buildTabPianificatore(
                            sessioniPianificatore, provider),
                        _buildTabFocus(provider.getPendingTasks()),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  // FAB dipendente dalla tab:
  //  - Oggi          → niente FAB (i "+" sono inline nelle sezioni)
  //  - Pianificatore → "+ Pianifica" (crea sessione)
  //  - Focus         → niente FAB
  Widget? _buildFab() {
    if (_currentSegment != 1) return null;
    return FloatingActionButton.extended(
      heroTag: 'fab_planning',
      backgroundColor: AppColors.planning,
      foregroundColor: Colors.white,
      elevation: 0,
      onPressed: () => _apriFormSessione(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Pianifica',
          style: TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // TAB 1 — OGGI
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabOggi(
      List<StudySession> sessioni, List<Task> task, PlannerProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final taskInCorso = task.where((t) => !t.completata).toList();
    final taskCompletati = task.where((t) => t.completata).toList();
    final sessioniInCorso = sessioni.where((s) => !s.completata).toList();
    final sessioniCompletate = sessioni.where((s) => s.completata).toList();

    final tuttoVuoto = sessioni.isEmpty && task.isEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // ── Intestazione sezione Attività con "+ Attività" ──
        _SectionTitleWithAction(
          title: 'Le mie attività',
          isDark: isDark,
          actionLabel: 'Attività',
          onAction: () => _apriFormTask(),
        ),
        const SizedBox(height: 8),

        if (tuttoVuoto)
          _EmptyState(
            icon: Icons.wb_sunny_outlined,
            text: 'Libero! Nessuna attività o sessione per oggi.',
          )
        else ...[
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
                      onTap: () => _apriFormTask(task: t),
                      isDark: isDark,
                    )),
                ...sessioniInCorso.map((s) => _SessionRow(
                      session: s,
                      sottotitolo:
                          '${provider.getCourseById(s.courseId ?? '')?.nome ?? "Generico"} · ${s.tipo}',
                      onToggle: () => provider.updateStudySession(
                          s.copyWith(completata: !s.completata)),
                      onEdit: () => _apriFormSessione(sessione: s),
                      isDark: isDark,
                    )),
              ],
            ),
            const SizedBox(height: 24),
          ],
          if (taskCompletati.isNotEmpty ||
              sessioniCompletate.isNotEmpty) ...[
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
                      onTap: () => _apriFormTask(task: t),
                      isDark: isDark,
                    )),
                ...sessioniCompletate.map((s) => _SessionRow(
                      session: s,
                      sottotitolo:
                          '${provider.getCourseById(s.courseId ?? '')?.nome ?? "Generico"} · ${s.tipo}',
                      onToggle: () => provider.updateStudySession(
                          s.copyWith(completata: !s.completata)),
                      onEdit: () => _apriFormSessione(sessione: s),
                      isDark: isDark,
                    )),
              ],
            ),
          ],
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
        // ── Toggle Giornaliera/Settimanale + Data ──
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

        // ── Filtri ──
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
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 90),
                  children: [
                    if (sessioniInCorso.isNotEmpty)
                      _CardGroup(
                        isDark: isDark,
                        children: sessioniInCorso
                            .map((s) => _SessionRow(
                                  session: s,
                                  sottotitolo:
                                      _sottotitoloSessione(s, provider),
                                  onToggle: () =>
                                      provider.updateStudySession(s.copyWith(
                                          completata: !s.completata)),
                                  onEdit: () =>
                                      _apriFormSessione(sessione: s),
                                  onDelete: () async {
                                    final c = await _confirmDeleteSessione(
                                        context, s);
                                    if (c == true && context.mounted) {
                                      await provider
                                          .deleteStudySession(s.id);
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
                                  sottotitolo:
                                      _sottotitoloSessione(s, provider),
                                  onToggle: () =>
                                      provider.updateStudySession(s.copyWith(
                                          completata: !s.completata)),
                                  onEdit: () =>
                                      _apriFormSessione(sessione: s),
                                  onDelete: () async {
                                    final c = await _confirmDeleteSessione(
                                        context, s);
                                    if (c == true && context.mounted) {
                                      await provider
                                          .deleteStudySession(s.id);
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
  // TAB 3 — FOCUS (Tecnica Pomodoro: Pomodoro / Pausa + reset)
  // ═══════════════════════════════════════════════════════════════
  Widget _buildTabFocus(List<Task> pendingTasks) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = _secondsRemaining / _currentTotal;
    final isPomodoro = _focusType == FocusType.pomodoro;
    // Colore accento: rosso per Pomodoro, verde per Pausa (come il prof).
    final accent =
        isPomodoro ? AppColors.danger : AppColors.success;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          // ── Titolo "Tecnica Pomodoro" ──
          Text(
            'Tecnica Pomodoro',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isPomodoro
                ? '25 minuti di studio concentrato'
                : '5 minuti di pausa',
            style: TextStyle(fontSize: 14, color: AppColors.textMuted),
          ),
          const SizedBox(height: 20),

          // ── Selettore Pomodoro / Pausa ──
          _MiniSegment(
            options: const ['Pomodoro', 'Pausa'],
            selectedIndex: isPomodoro ? 0 : 1,
            onChanged: (i) => _switchFocusType(
                i == 0 ? FocusType.pomodoro : FocusType.pausa),
            isDark: isDark,
            fullWidth: true,
          ),
          const SizedBox(height: 24),

          // ── Selettore obiettivo (solo per Pomodoro) ──
          if (isPomodoro)
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
          const SizedBox(height: 36),

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
                        : accent.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(accent),
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
                      _isTimerRunning
                          ? 'In corso'
                          : (isPomodoro ? 'Pomodoro' : 'Pausa'),
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
          const SizedBox(height: 36),

          // ── Controlli: Reset + Avvia/Pausa ──
          Row(
            children: [
              // Tasto Reset (sempre presente, come il prof)
              _CircleControl(
                icon: Icons.refresh_rounded,
                onTap: _resetTimer,
                isDark: isDark,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: GestureDetector(
                  onTap: _isTimerRunning ? _pauseTimer : _startTimer,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isTimerRunning ? AppColors.warning : accent,
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
                          _isTimerRunning
                              ? 'Pausa'
                              : (isPomodoro
                                  ? 'Inizia Focus'
                                  : 'Inizia Pausa'),
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
                color:
                    isDark ? Colors.white70 : AppColors.textSecondary,
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
// MINI SEGMENT (Giornaliera/Settimanale, Pomodoro/Pausa)
// ═══════════════════════════════════════════════════════════════
class _MiniSegment extends StatelessWidget {
  final List<String> options;
  final int selectedIndex;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final bool fullWidth;

  const _MiniSegment({
    required this.options,
    required this.selectedIndex,
    required this.onChanged,
    required this.isDark,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: List.generate(options.length, (i) {
        final selected = i == selectedIndex;
        final chip = AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? (isDark ? const Color(0xFF3A3A3C) : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          alignment: Alignment.center,
          child: Text(
            options[i],
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              color: selected
                  ? (isDark ? Colors.white : AppColors.textPrimary)
                  : AppColors.textMuted,
            ),
          ),
        );
        return fullWidth
            ? Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(i),
                  behavior: HitTestBehavior.opaque,
                  child: chip,
                ),
              )
            : GestureDetector(
                onTap: () => onChanged(i),
                behavior: HitTestBehavior.opaque,
                child: chip,
              );
      }),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(9),
      ),
      padding: const EdgeInsets.all(3),
      child: row,
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
          if (espanso)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: [
                  // Filtro Corso
                  _FilterDropdownRow<Course?>(
                    label: 'Corso',
                    value: filtroCorso,
                    isDark: isDark,
                    items: [
                      DropdownMenuItem<Course?>(
                        value: null,
                        child: Text('Tutti i Corsi',
                            style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary)),
                      ),
                      ...corsi.map((c) => DropdownMenuItem<Course?>(
                            value: c,
                            child: Text(c.nome,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.textPrimary)),
                          )),
                    ],
                    onChanged: onCorsoChanged,
                  ),
                  const SizedBox(height: 10),
                  // Filtro Tipo
                  _FilterDropdownRow<String>(
                    label: 'Tipo',
                    value: filtroTipo,
                    isDark: isDark,
                    items: const [
                      'Tutti',
                      'Studio',
                      'Ripasso',
                      'Esercitazione',
                      'Progetto',
                      'Consegna'
                    ]
                        .map((e) => DropdownMenuItem<String>(
                            value: e, child: Text(e)))
                        .toList(),
                    onChanged: (v) => onTipoChanged(v!),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// Riga filtro: etichetta a sinistra + dropdown "nudo" a destra
class _FilterDropdownRow<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final bool isDark;

  const _FilterDropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : AppColors.groupedBackground,
              borderRadius: BorderRadius.circular(10),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                isExpanded: true,
                value: value,
                icon: Icon(Icons.unfold_more_rounded,
                    size: 18, color: AppColors.textMuted),
                style: TextStyle(
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                items: items,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SECTION TITLE con azione "+ ..." (per "Le mie attività")
// ═══════════════════════════════════════════════════════════════
class _SectionTitleWithAction extends StatelessWidget {
  final String title;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isDark;

  const _SectionTitleWithAction({
    required this.title,
    required this.actionLabel,
    required this.onAction,
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
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded,
                        size: 18, color: AppColors.planningDeep),
                    const SizedBox(width: 2),
                    Text(
                      actionLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.planningDeep,
                      ),
                    ),
                  ],
                ),
              ),
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
// CARD GROUP
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
  final VoidCallback? onTap;
  final bool isDark;

  const _TaskRow({
    required this.task,
    required this.sottotitolo,
    required this.onToggle,
    this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppColors.priorita(task.priorita);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
                          : (isDark
                              ? Colors.white38
                              : AppColors.textMuted),
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
                        color: isDark
                            ? Colors.white
                            : AppColors.textPrimary,
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
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// SESSION ROW
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
              style: TextStyle(fontSize: 15, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}