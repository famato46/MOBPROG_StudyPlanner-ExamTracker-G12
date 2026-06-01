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
import '../widgets/planning_calendar.dart';
import '../widgets/planning_filter_section.dart';
import '../widgets/planning_task_picker.dart';

// Tipo di sessione del timer Focus
enum FocusType { pomodoro, pausa }

class PlanningScreen extends StatefulWidget {
  const PlanningScreen({super.key});

  @override
  State<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends State<PlanningScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;
  late final TabController _focusTabController;
  late final TabController _sessioniTabController; 

  // 0 = Attività, 1 = Sessioni, 2 = Focus
  int _currentSegment = 0;

  DateTime _giornoPianificatore = DateTime.now();

  // Filtri Tab Sessioni
  Course? _filtroCorso;
  String _filtroTipoAttivita = 'Tutti';
  bool _isVistaSettimanale = false;
  bool _filtriEspansi = false;

  // Stato Timer Focus 
  static const int _pomodoroSeconds = 25 * 60;
  static const int _pausaSeconds = 5 * 60;

  int _timerSeconds = _pomodoroSeconds;

  FocusType _focusType = FocusType.pomodoro;
  Timer? _focusTimer;
  bool _isTimerRunning = false;
  Task? _selectedTaskForPomodoro;

  int get _currentTotal =>
      _focusType == FocusType.pomodoro ? _pomodoroSeconds : _pausaSeconds;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      if (_currentSegment != _tabController.index) {
        if (_tabController.index != 2 && _isTimerRunning) _pauseTimer();
        setState(() => _currentSegment = _tabController.index);
      }
    });

    _focusTabController = TabController(length: 2, vsync: this);
    _focusTabController.addListener(() {
      if (_focusTabController.indexIsChanging) return;
      _switchFocusType(
        _focusTabController.index == 0 ? FocusType.pomodoro : FocusType.pausa,
      );
    });

    _sessioniTabController = TabController(length: 2, vsync: this);
    _sessioniTabController.addListener(() {
      if (_sessioniTabController.indexIsChanging) return;
      setState(() => _isVistaSettimanale = _sessioniTabController.index == 1);
    });
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _tabController.dispose();
    _focusTabController.dispose();
    _sessioniTabController.dispose();
    super.dispose();
  }

  // TIMER 
  void _startTimer() {
    if (_focusType == FocusType.pomodoro && _selectedTaskForPomodoro == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Seleziona un obiettivo prima di avviare il Pomodoro!')),
      );
      return;
    }
    setState(() => _isTimerRunning = true);
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
  setState(() {
    if (_timerSeconds > 0) {
      _timerSeconds--;
    } else {
      _completaSessione();
    }
  });
});
  }

  void _pauseTimer() {
    _focusTimer?.cancel();
    setState(() => _isTimerRunning = false);
  }

  void _resetTimer() {
    _focusTimer?.cancel();
    setState(() => _timerSeconds = _currentTotal);
    setState(() => _isTimerRunning = false);
  }

  void _switchFocusType(FocusType type) {
    _focusTimer?.cancel();
    setState(() {
  _focusType = type;
  _isTimerRunning = false;
  _timerSeconds = type == FocusType.pomodoro ? _pomodoroSeconds : _pausaSeconds;
});
    setState(() {
      _focusType = type;
      _isTimerRunning = false;
    });
    final targetIndex = type == FocusType.pomodoro ? 0 : 1;
    if (_focusTabController.index != targetIndex) {
      _focusTabController.animateTo(targetIndex);
    }
  }

  Future<void> _completaSessione() async {
    _focusTimer?.cancel();

    if (_focusType == FocusType.pomodoro && _selectedTaskForPomodoro != null) {
      await Provider.of<PlannerProvider>(context, listen: false)
          .savePomodoroSession(
        titolo: 'Focus: ${_selectedTaskForPomodoro!.titolo}',
        courseId: _selectedTaskForPomodoro!.courseId,
        examId: _selectedTaskForPomodoro!.examId,
        taskId: _selectedTaskForPomodoro!.id,
        durataEffettiva: _pomodoroSeconds ~/ 60,
      );
    } else if (_focusType == FocusType.pausa) {
      await Provider.of<PlannerProvider>(context, listen: false)
          .savePausaSession(
        durataEffettiva: _pausaSeconds ~/ 60,
      );
    }

    setState(() => _isTimerRunning = false);
    setState(() => _timerSeconds = _currentTotal);
    if (mounted) _mostraDialogFine();
  }

  void _mostraDialogFine() {
    final isPomodoro = _focusType == FocusType.pomodoro;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  // HELPER per conversione da Task a Map (per database)
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
    return !date.isBefore(inizioSettimana) && date.isBefore(fineSettimana);
  }

  void _apriFormSessione({StudySession? sessione}) {
    final provider = context.read<PlannerProvider>();
    if (provider.courses.isEmpty && sessione == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Inserisci prima un Corso nell\'apposita schermata!')));
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

  void _apriFormTask({Task? task}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(taskToEdit: task),
      ),
    );
  }

  String _sottotitoloTask(Task t, PlannerProvider provider) {
    final corso = provider.getCourseById(t.courseId ?? '')?.nome ?? 'Generico';
    if (t.scadenza != null) {
      final d = t.scadenza!;
      final oggi = DateTime.now();
      final oggiDate = DateTime(oggi.year, oggi.month, oggi.day);
      final tDate = DateTime(d.year, d.month, d.day);

      if (tDate.isBefore(oggiDate)) {
        return 'Scaduta il ${DateFormat('dd/MM', 'it_IT').format(d)} · $corso';
      } else if (tDate.isAfter(oggiDate)) {
        return '${DateFormat('EE dd/MM', 'it_IT').format(d)} · $corso';
      }
    }
    return corso;
  }

  String _sottotitoloSessioneAttivita(StudySession s, PlannerProvider provider) {
    final corso = provider.getCourseById(s.courseId ?? '')?.nome ?? 'Generico';
    final d = s.data;
    final oggi = DateTime.now();
    final oggiDate = DateTime(oggi.year, oggi.month, oggi.day);
    final sDate = DateTime(d.year, d.month, d.day);

    if (sDate.isBefore(oggiDate)) {
      return 'Scaduta il ${DateFormat('dd/MM', 'it_IT').format(d)} · $corso · ${s.tipo}';
    } else if (sDate.isAfter(oggiDate)) {
      return '${DateFormat('EE dd/MM', 'it_IT').format(d)} · $corso · ${s.tipo}';
    }
    return '$corso · ${s.tipo}';
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PlannerProvider>(context);

    // DATI TAB SESSIONI 
    var sessioniPianificatore = provider.studySessions.where((s) {
      final tipo = s.tipo.toLowerCase();
      if (tipo == 'pomodoro' || tipo == 'pausa') return false; // Per escludere le sessioni generate dai timer nel tab sessioni

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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            const _Header(),
            const SizedBox(height: 8),
            _PlanningTabBar(
              controller: _tabController,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: provider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : IndexedStack(
                      index: _currentSegment,
                      children: [
                        _buildTabOggi(provider),
                        _buildTabPianificatore(sessioniPianificatore, provider),
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

  Widget? _buildFab() {
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

  Future<bool?> _confirmDeleteTask(BuildContext context, Task t) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Elimina attività'),
        content: Text('Eliminare "${t.titolo}"?'),
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
  }

  // TAB 1 — Attività 
  Widget _buildTabOggi(PlannerProvider provider) {
    final oggi = DateTime.now();
    final oggiDate = DateTime(oggi.year, oggi.month, oggi.day);

    final taskOggi = provider.tasks.where((t) {
      if (t.scadenza == null) return false;
      final scad = DateTime(t.scadenza!.year, t.scadenza!.month, t.scadenza!.day);
      return !scad.isAfter(oggiDate);
    }).toList()
      ..sort((a, b) {
  if (a.completata != b.completata) return a.completata ? 1 : -1;
  return _pesoPriorita(b.priorita).compareTo(_pesoPriorita(a.priorita));
});

    final taskFuturi = provider.tasks.where((t) {
      if (t.scadenza == null) return false;
      final scad = DateTime(t.scadenza!.year, t.scadenza!.month, t.scadenza!.day);
      return scad.isAfter(oggiDate);
    }).toList()
      ..sort((a, b) {
  if (a.completata != b.completata) return a.completata ? 1 : -1;
  return a.scadenza!.compareTo(b.scadenza!);
});
    final tuttoOggiVuoto = taskOggi.isEmpty;
    final tuttoFuturoVuoto = taskFuturi.isEmpty;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        _HeaderLabel(title: 'Obiettivi di oggi'),

        if (tuttoOggiVuoto)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Nessuna attività programmata o in sospeso per oggi.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          )
        else
          _CardGroup(
            children: [
              ...taskOggi.map((t) => _TaskRow(
                    task: t,
                    sottotitolo: _sottotitoloTask(t, provider),
                    onToggle: () => provider.toggleTaskCompletion(t.id),
                    onTap: () => _apriFormTask(task: t),
                    onDelete: () async {
                      final c = await _confirmDeleteTask(context, t);
                      if (c == true && context.mounted) {
                        await provider.deleteTask(t.id);
                      }
                    },
                  )),
            ],
          ),

        const SizedBox(height: 36),

        _HeaderLabel(title: 'In programma'),

        if (tuttoFuturoVuoto)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              'Nessuna attività futura in programma.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
          )
        else
          _CardGroup(
            children: [
              ...taskFuturi.map((t) => _TaskRow(
                    task: t,
                    sottotitolo: _sottotitoloTask(t, provider),
                    onToggle: () => provider.toggleTaskCompletion(t.id),
                    onTap: () => _apriFormTask(task: t),
                    onDelete: () async {
                      final c = await _confirmDeleteTask(context, t);
                      if (c == true && context.mounted) {
                        await provider.deleteTask(t.id);
                      }
                    },
                  )),
            ],
          ),
      ],
    );
  }

  // TAB 2 — Sessioni 
  Widget _buildTabPianificatore(
    List<StudySession> sessioni, PlannerProvider provider) {
    final sessioniInCorso = sessioni.where((s) => !s.completata).toList();
    final sessioniCompletate = sessioni.where((s) => s.completata).toList();
    final filtriAttivi =
        _filtroCorso != null || _filtroTipoAttivita != 'Tutti';

    final giorniConSessioni = provider.studySessions
        .where((s) {
          final t = s.tipo.toLowerCase();
          return t != 'pomodoro' && t != 'pausa';
        })
        .map((s) => DateTime(s.data.year, s.data.month, s.data.day))
        .toSet();

    return LayoutBuilder(
      builder: (context, constraints) {
        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: constraints.maxHeight * 0.75),
                child: PlanningCalendarGrid(
                  selectedDay: _giornoPianificatore,
                  giorniConSessioni: giorniConSessioni,
                  onDaySelected: (d) => setState(() => _giornoPianificatore = d),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SubTabBar(
                controller: _sessioniTabController,
              ),
            ),
            SliverToBoxAdapter(
              child: PlanningFilterSection(
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
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 8)),
            if (sessioni.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(
                  icon: Icons.event_busy_outlined,
                  text: 'Nessun impegno corrisponde ai criteri.',
                ),
              )
            else ...[
              if (sessioniInCorso.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _CardGroup(
                      children: sessioniInCorso
                          .map((s) => _SessionRow(
                                session: s,
                                sottotitolo: _sottotitoloSessioneAttivita(s, provider),
                                onToggle: () => provider.updateStudySession(
                                    s.copyWith(completata: !s.completata)),
                                onEdit: () => _apriFormSessione(sessione: s),
                                onDelete: () async {
                                  final c =
                                      await _confirmDeleteSessione(context, s);
                                  if (c == true && context.mounted) {
                                    await provider.deleteStudySession(s.id);
                                  }
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ),
              if (sessioniCompletate.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _SectionLabel(
                        label: 'Completate',
                        color: AppColors.success),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _CardGroup(
                      children: sessioniCompletate
                          .map((s) => _SessionRow(
                                session: s,
                                sottotitolo: _sottotitoloSessioneAttivita(s, provider),
                                onToggle: () => provider.updateStudySession(
                                    s.copyWith(completata: !s.completata)),
                                onEdit: () => _apriFormSessione(sessione: s),
                                onDelete: () async {
                                  final c =
                                      await _confirmDeleteSessione(context, s);
                                  if (c == true && context.mounted) {
                                    await provider.deleteStudySession(s.id);
                                  }
                                },
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 90)),
            ],
          ],
        );
      }
    );
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
            child: Text('Elimina', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  // TAB 3 — Focus (Tecnica Pomodoro)
  Widget _buildTabFocus(List<Task> pendingTasks) {
    final isPomodoro = _focusType == FocusType.pomodoro;
    final accent = isPomodoro ? AppColors.danger : AppColors.success;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        children: [
          Text(
            'Tecnica Pomodoro',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: Theme.of(context).colorScheme.onSurface,
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(4),
              child: TabBar(
                controller: _focusTabController,
                indicator: BoxDecoration(
                  color: isPomodoro ? AppColors.danger : AppColors.success,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
                tabs: const [
                  Tab(
                    icon: Icon(Icons.timer_outlined, size: 20),
                    text: 'Pomodoro',
                  ),
                  Tab(
                    icon: Icon(Icons.local_cafe_outlined, size: 20),
                    text: 'Pausa',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            height: 56,
            child: isPomodoro
                ? PlanningTaskPickerButton(
                    selectedTask: _selectedTaskForPomodoro,
                    pendingTasks: pendingTasks,
                    enabled: !_isTimerRunning,
                    onSelected: (t) =>
                        setState(() => _selectedTaskForPomodoro = t),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 36),

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
              value: _timerSeconds / _currentTotal,
              strokeWidth: 8,
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.08)
                  : accent.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(accent),
          ),
        ),
              Column(
              mainAxisSize: MainAxisSize.min,
            children: [
            Text(
            '${(_timerSeconds ~/ 60).toString().padLeft(2, '0')}:${(_timerSeconds % 60).toString().padLeft(2, '0')}',
            style: TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
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

          Row(
            children: [
              _CircleControl(
                icon: Icons.refresh_rounded,
                onTap: _resetTimer,
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

// UI COMPONENTI AGGIUNTIVI
class _HeaderLabel extends StatelessWidget {
  final String title;
  

  const _HeaderLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Organizza studio e sessioni di focus',
              style: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlanningTabBar extends StatelessWidget {
  final TabController controller;
  

  const _PlanningTabBar({
    required this.controller,
  });

  static const _labels = ['Attività', 'Sessioni', 'Focus'];
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
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: AppColors.planning,
            borderRadius: BorderRadius.circular(10),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          labelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: -0.2),
          unselectedLabelStyle: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: List.generate(
            3,
            (i) => Tab(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_icons[i], size: 18),
                  const SizedBox(height: 2),
                  Text(_labels[i]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color? color;

  const _SectionLabel({
    required this.label,
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
          color: color ?? Theme.of(context).colorScheme.onSurface,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

class _CardGroup extends StatelessWidget {
  final List<Widget> children;

  const _CardGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: _withDividers(children, context)),
    );
  }

  List<Widget> _withDividers(List<Widget> rows, BuildContext context) {
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
            color: Theme.of(context).dividerColor,
          ),
        ));
      }
    }
    return result;
  }
}

class _TaskRow extends StatelessWidget {
  final Task task;
  final String sottotitolo;
  final VoidCallback onToggle;
  final VoidCallback? onTap;
  final Future<void> Function()? onDelete;

  const _TaskRow({
    required this.task,
    required this.sottotitolo,
    required this.onToggle,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = AppColors.priorita(task.priorita);

    Widget content = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
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
                          : Theme.of(context).colorScheme.outline,
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
                        color: task.completata
                            ? AppColors.textMuted
                            : Theme.of(context).colorScheme.onSurface,
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
                        color: task.completata
                            ? AppColors.textMuted.withValues(alpha: 0.6)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
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
                  color: priorityColor.withValues(
                      alpha: task.completata ? 0.05 : 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  task.priorita.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: priorityColor.withValues(
                        alpha: task.completata ? 0.5 : 1.0),
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (onDelete != null) {
      return Dismissible(
        key: ValueKey('task_${task.id}'),
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

class _SessionRow extends StatelessWidget {
  final StudySession session;
  final String sottotitolo;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final Future<void> Function()? onDelete;

  const _SessionRow({
    required this.session,
    required this.sottotitolo,
    required this.onToggle,
    required this.onEdit,
    this.onDelete,
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
                      : Theme.of(context).colorScheme.outline,
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
            color: session.completata 
                ? AppColors.textMuted.withValues(alpha: 0.6) 
                : (isConsegna ? AppColors.danger : AppColors.planningDeep),
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
                    color: session.completata
                        ? AppColors.textMuted
                        : Theme.of(context).colorScheme.onSurface,
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              child: Icon(
                Icons.edit_outlined, 
                size: 18, 
                color: session.completata ? AppColors.textMuted : AppColors.iosBlue
              ),
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

class _CircleControl extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleControl({
    required this.icon,
    required this.onTap,
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
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      ),
    );
  }
}

class _SubTabBar extends StatelessWidget {
  final TabController controller;
  const _SubTabBar({required this.controller});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(9),
        ),
        padding: const EdgeInsets.all(3),
        child: TabBar(
          controller: controller,
          indicator: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(7),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor: AppColors.textMuted,
          labelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: -0.2),
          unselectedLabelStyle: const TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: -0.2),
          splashFactory: NoSplash.splashFactory,
          overlayColor: WidgetStateProperty.all(Colors.transparent),
          tabs: const [
            Tab(text: 'Giornaliera'),
            Tab(text: 'Settimanale'),
          ],
        ),
      ),
    );
  }
}

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