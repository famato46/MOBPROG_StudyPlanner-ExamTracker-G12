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

  // ─────────────────────────── TIMER ───────────────────────────
  // Usiamo un ValueNotifier per i secondi rimanenti: questo garantisce
  // che il cerchio del timer si aggiorni a ogni tick in real-time anche
  // dentro un IndexedStack (che talvolta ottimizza i rebuild delle tab
  // non in primo piano). Il resto dello stato (isRunning, focusType)
  // resta in setState normale.
  final ValueNotifier<int> _secondsNotifier =
      ValueNotifier(_pomodoroSeconds);

  // Alias per compatibilità con il resto del codice.
  int get _secondsRemaining => _secondsNotifier.value;

  FocusType _focusType = FocusType.pomodoro;
  Timer? _focusTimer;
  bool _isTimerRunning = false;
  Task? _selectedTaskForPomodoro;

  int get _currentTotal =>
      _focusType == FocusType.pomodoro ? _pomodoroSeconds : _pausaSeconds;

  @override
  void dispose() {
    _focusTimer?.cancel();
    _secondsNotifier.dispose();
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
      if (_secondsNotifier.value > 0) {
        // Aggiorniamo il ValueNotifier: il cerchio si ridisegna in real-time
        // senza dover ricostruire l'intero albero di widget.
        _secondsNotifier.value--;
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
    _secondsNotifier.value = _currentTotal;
    setState(() => _isTimerRunning = false);
  }

  // Cambia tipo (Pomodoro/Pausa): ferma il timer e resetta i secondi.
  void _switchFocusType(FocusType type) {
    _focusTimer?.cancel();
    _secondsNotifier.value =
        type == FocusType.pomodoro ? _pomodoroSeconds : _pausaSeconds;
    setState(() {
      _focusType = type;
      _isTimerRunning = false;
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
    });
    _secondsNotifier.value = _currentTotal;
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
    // Tab Pianificatore → FAB verde "+ Sessione"
    if (_currentSegment == 1) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.planning.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'fab_planning',
          backgroundColor: AppColors.planning,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const CircleBorder(),
          onPressed: () => _apriFormSessione(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      );
    }
    // Tab Oggi → FAB identico al Pianificatore, apre form Task
    if (_currentSegment == 0) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.planning.withValues(alpha: 0.55),
              blurRadius: 18,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton(
          heroTag: 'fab_oggi',
          backgroundColor: AppColors.planning,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const CircleBorder(),
          onPressed: () => _apriFormTask(),
          child: const Icon(Icons.add_rounded, size: 28),
        ),
      );
    }
    return null;
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
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _SectionLabel(label: 'Le mie attività di oggi', isDark: isDark),
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

    // Tutti i giorni che hanno almeno una sessione (per i marker)
    final giorniConSessioni = provider.studySessions
        .map((s) => DateTime(s.data.year, s.data.month, s.data.day))
        .toSet();

    return Column(
      children: [
        // ── Calendario a griglia (GridView 7 colonne) ──
        _CalendarGrid(
          selectedDay: _giornoPianificatore,
          giorniConSessioni: giorniConSessioni,
          onDaySelected: (d) => setState(() => _giornoPianificatore = d),
          isDark: isDark,
        ),

        // ── Toggle Giornaliera/Settimanale ──
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
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
              // Label data selezionata
              Text(
                _formatGiornoPianificatore(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                  letterSpacing: -0.2,
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
    final isPomodoro = _focusType == FocusType.pomodoro;
    final accent = isPomodoro ? AppColors.danger : AppColors.success;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          // ── Titolo ──
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

          // ── Selettore Pomodoro / Pausa (SENZA emoji) ──
          _MiniSegment(
            options: const ['Pomodoro', 'Pausa'],
            selectedIndex: isPomodoro ? 0 : 1,
            onChanged: (i) =>
                _switchFocusType(i == 0 ? FocusType.pomodoro : FocusType.pausa),
            isDark: isDark,
            fullWidth: true,
          ),
          const SizedBox(height: 24),

          // ── Selettore obiettivo (solo Pomodoro). Usa bottom sheet iOS. ──
          SizedBox(
            height: 56,
            child: isPomodoro
                ? _TaskPickerButton(
                    selectedTask: _selectedTaskForPomodoro,
                    pendingTasks: pendingTasks,
                    enabled: !_isTimerRunning,
                    onSelected: (t) =>
                        setState(() => _selectedTaskForPomodoro = t),
                    isDark: isDark,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 36),

          // ── Cerchio timer con ValueListenableBuilder ──
          // ValueListenableBuilder si iscrive al ValueNotifier<int> e
          // ricostruisce SOLO il cerchio a ogni tick del timer (60fps
          // percepiti, senza ricostruire l'intero tab). Questo risolve
          // il problema "il timer va ma il numero non si aggiorna in
          // tempo reale" causato dall'IndexedStack che ottimizzava i
          // rebuild dei widget non in primo piano.
          ValueListenableBuilder<int>(
            valueListenable: _secondsNotifier,
            builder: (context, seconds, _) {
              final progress = seconds / _currentTotal;
              final mm = (seconds ~/ 60).toString().padLeft(2, '0');
              final ss = (seconds % 60).toString().padLeft(2, '0');
              return SizedBox(
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
                          '$mm:$ss',
                          style: TextStyle(
                            fontSize: 52,
                            fontWeight: FontWeight.w800,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
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
              );
            },
          ),
          const SizedBox(height: 36),

          // ── Controlli: Reset + Avvia/Pausa ──
          Row(
            children: [
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
                              : (isPomodoro ? 'Inizia Focus' : 'Inizia Pausa'),
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
// ═══════════════════════════════════════════════════════════════
// CALENDAR GRID — Griglia mensile 7 colonne (pattern del prof)
// Ogni cella è un GestureDetector. I giorni con sessioni mostrano
// un pallino verde (marker). Il giorno selezionato ha sfondo verde.
// ═══════════════════════════════════════════════════════════════
class _CalendarGrid extends StatefulWidget {
  final DateTime selectedDay;
  final Set<DateTime> giorniConSessioni;
  final ValueChanged<DateTime> onDaySelected;
  final bool isDark;

  const _CalendarGrid({
    required this.selectedDay,
    required this.giorniConSessioni,
    required this.onDaySelected,
    required this.isDark,
  });

  @override
  State<_CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<_CalendarGrid> {
  // Mese correntemente visualizzato
  late DateTime _viewMonth;

  @override
  void initState() {
    super.initState();
    _viewMonth =
        DateTime(widget.selectedDay.year, widget.selectedDay.month);
  }

  void _prevMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final oggi = DateTime.now();
    final oggiNorm = DateTime(oggi.year, oggi.month, oggi.day);

    // Primo giorno del mese e offset (lun=0)
    final primoDelMese = DateTime(_viewMonth.year, _viewMonth.month, 1);
    final offset = (primoDelMese.weekday - 1) % 7; // lun=0 ... dom=6
    final giorniNelMese =
        DateTime(_viewMonth.year, _viewMonth.month + 1, 0).day;
    final totalCells = offset + giorniNelMese;
    final rows = (totalCells / 7).ceil();

    // Nome mese in italiano
    const mesi = [
      '', 'Gennaio', 'Febbraio', 'Marzo', 'Aprile', 'Maggio', 'Giugno',
      'Luglio', 'Agosto', 'Settembre', 'Ottobre', 'Novembre', 'Dicembre'
    ];
    const giorniSettimana = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // ── Header mese ──
          Row(
            children: [
              GestureDetector(
                onTap: _prevMonth,
                child: Icon(Icons.chevron_left_rounded,
                    color: AppColors.planningDeep, size: 24),
              ),
              Expanded(
                child: Text(
                  '${mesi[_viewMonth.month]} ${_viewMonth.year}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ),
              GestureDetector(
                onTap: _nextMonth,
                child: Icon(Icons.chevron_right_rounded,
                    color: AppColors.planningDeep, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ── Intestazione giorni L M M G V S D ──
          Row(
            children: giorniSettimana
                .map((g) => Expanded(
                      child: Center(
                        child: Text(
                          g,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),

          // ── Griglia giorni (GridView del prof) ──
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 2,
            childAspectRatio: 1.0,
            children: List.generate(rows * 7, (index) {
              final dayNumber = index - offset + 1;
              final isValidDay =
                  dayNumber >= 1 && dayNumber <= giorniNelMese;

              if (!isValidDay) {
                return const SizedBox.shrink();
              }

              final thisDay = DateTime(
                  _viewMonth.year, _viewMonth.month, dayNumber);
              final thisDayNorm =
                  DateTime(thisDay.year, thisDay.month, thisDay.day);
              final isSelected = thisDayNorm ==
                  DateTime(widget.selectedDay.year,
                      widget.selectedDay.month, widget.selectedDay.day);
              final isOggi = thisDayNorm == oggiNorm;
              final hasSession =
                  widget.giorniConSessioni.contains(thisDayNorm);

              return GestureDetector(
                onTap: () => widget.onDaySelected(thisDay),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.planning
                        : isOggi
                            ? AppColors.planning.withValues(alpha: 0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$dayNumber',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected || isOggi
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: isSelected
                              ? Colors.white
                              : isOggi
                                  ? AppColors.planningDeep
                                  : (isDark
                                      ? Colors.white
                                      : AppColors.textPrimary),
                        ),
                      ),
                      // Pallino marker se ci sono sessioni
                      if (hasSession && !isSelected)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: AppColors.planningDeep,
                            shape: BoxShape.circle,
                          ),
                        ),
                      if (hasSession && isSelected)
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: const BoxDecoration(
                            color: Colors.white70,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

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
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Column(
                children: [
                  _FilterPickerRow(
                    label: 'Corso',
                    displayValue: filtroCorso?.nome ?? 'Tutti',
                    options: [
                      ('__tutti__', 'Tutti i corsi'),
                      ...corsi.map((c) => (c.id, c.nome)),
                    ],
                    currentValue: filtroCorso?.id ?? '__tutti__',
                    onSelected: (v) {
                      if (v == '__tutti__') {
                        onCorsoChanged(null);
                      } else {
                        onCorsoChanged(
                            corsi.firstWhere((c) => c.id == v));
                      }
                    },
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _FilterPickerRow(
                    label: 'Tipo',
                    displayValue: filtroTipo,
                    options: const [
                      ('Tutti', 'Tutti'),
                      ('Studio', 'Studio'),
                      ('Ripasso', 'Ripasso'),
                      ('Esercitazione', 'Esercitazione'),
                      ('Progetto', 'Progetto'),
                      ('Consegna', 'Consegna'),
                    ],
                    currentValue: filtroTipo,
                    onSelected: onTipoChanged,
                    isDark: isDark,
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
// FILTER PICKER ROW — iOS bottom sheet (niente DropdownButton Material)
// ═══════════════════════════════════════════════════════════════
// Il DropdownButton di Flutter si apre dall'alto con stile Material
// e non è conforme allo stile iOS. Lo sostituiamo con un tasto
// che apre un showModalBottomSheet con lista di opzioni — stesso
// pattern usato in task_form_screen e course_form_screen.
class _FilterPickerRow extends StatelessWidget {
  final String label;
  final String displayValue;
  final List<(String, String)> options; // (valore, etichetta)
  final String currentValue;
  final ValueChanged<String> onSelected;
  final bool isDark;

  const _FilterPickerRow({
    required this.label,
    required this.displayValue,
    required this.options,
    required this.currentValue,
    required this.onSelected,
    required this.isDark,
  });

  void _openPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF1C1C1E) : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white24
                    : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            ...options.map((opt) {
              final (value, labelText) = opt;
              final selected = value == currentValue;
              return InkWell(
                onTap: () {
                  onSelected(value);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          labelText,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                      if (selected)
                        Icon(Icons.check_rounded,
                            color: AppColors.iosBlue, size: 20),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPicker(context),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : AppColors.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? Colors.white70
                      : AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayValue,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded,
                  size: 18, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
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
// TASK PICKER BUTTON — Bottom sheet iOS per selezionare il task
// nel Focus Pomodoro. Coerente con _FilterPickerRow.
// ═══════════════════════════════════════════════════════════════
class _TaskPickerButton extends StatelessWidget {
  final Task? selectedTask;
  final List<Task> pendingTasks;
  final bool enabled;
  final ValueChanged<Task?> onSelected;
  final bool isDark;

  const _TaskPickerButton({
    required this.selectedTask,
    required this.pendingTasks,
    required this.enabled,
    required this.onSelected,
    required this.isDark,
  });

  void _openPicker(BuildContext context) {
    if (!enabled) return;
    showModalBottomSheet(
      context: context,
      backgroundColor:
          isDark ? const Color(0xFF1C1C1E) : AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Text(
                'Seleziona obiettivo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
            const Divider(height: 1),
            if (pendingTasks.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Nessuna attività da completare.\nCreane una prima!',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 15),
                ),
              )
            else
              ...pendingTasks.map((t) {
                final selected = t.id == selectedTask?.id;
                return InkWell(
                  onTap: () {
                    onSelected(t);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.priorita(t.priorita),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            t.titolo,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (selected)
                          Icon(Icons.check_rounded,
                              color: AppColors.iosBlue, size: 20),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? () => _openPicker(context) : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: enabled ? 0.05 : 0.02)
                : (enabled ? AppColors.surface : AppColors.background),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  selectedTask?.titolo ?? 'Seleziona obiettivo',
                  style: TextStyle(
                    fontSize: 15,
                    color: selectedTask != null
                        ? (isDark ? Colors.white : AppColors.textPrimary)
                        : AppColors.textMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.unfold_more_rounded,
                color: enabled ? AppColors.textMuted : AppColors.textMuted.withValues(alpha: 0.4),
                size: 20,
              ),
            ],
          ),
        ),
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