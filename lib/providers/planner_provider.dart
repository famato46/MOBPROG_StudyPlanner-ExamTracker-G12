import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/course.dart';
import '../models/exam.dart';
import '../models/study_session.dart';
import '../models/task.dart';

/// PlannerProvider - Gestisce tutto lo stato dell'app
/// Segue il pattern Provider del professore: interagisce col DB e notifica la UI
class PlannerProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  // ========== STATE (Liste in memoria) ==========
  List<Course> _courses = [];
  List<Exam> _exams = [];
  List<StudySession> _studySessions = [];
  List<Task> _tasks = [];

  bool _isLoading = false;

  // ========== GETTERS PUBBLICI ==========
  List<Course> get courses => _courses;
  List<Exam> get exams => _exams;
  List<StudySession> get studySessions => _studySessions;
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  // ========== COSTRUTTORE ==========
  PlannerProvider() {
    loadData();
  }

  // ========== CARICAMENTO DATI ==========
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _courses = await _db.getCourses();
      _exams = await _db.getExams();
      _studySessions = await _db.getStudySessions();
      _tasks = await _db.getTasks();
    } catch (e) {
      debugPrint('Errore caricamento dati: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // =============================================
  // ========== CRUD CORSI =======================
  // =============================================

  Future<void> addCourse({
    required String nome,
    required String docente,
    required int cfu,
    required String semestre,
    String stato = 'da_iniziare',
    int? votoDesiderato,
    String? note,
    String? materialeAssociato,
  }) async {
    final newCourse = Course(
      id: _uuid.v4(),
      nome: nome,
      docente: docente,
      cfu: cfu,
      semestre: semestre,
      stato: stato,
      votoDesiderato: votoDesiderato,
      note: note,
      materialeAssociato: materialeAssociato,
    );

    await _db.insertCourse(newCourse);
    _courses.add(newCourse);
    notifyListeners();
  }

  Future<void> updateCourse(Course course) async {
    await _db.updateCourse(course);
    int index = _courses.indexWhere((c) => c.id == course.id);
    if (index != -1) {
      _courses[index] = course;
      notifyListeners();
    }
  }

  Future<void> deleteCourse(String id) async {
    await _db.deleteCourse(id);
    _courses.removeWhere((c) => c.id == id);
    // Rimuovi anche esami, sessioni e task collegati
    _exams.removeWhere((e) => e.courseId == id);
    _studySessions.removeWhere((s) => s.courseId == id);
    _tasks.removeWhere((t) => t.courseId == id);
    notifyListeners();
  }

  Course? getCourseById(String id) {
    try {
      return _courses.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  // =============================================
  // ========== CRUD ESAMI =======================
  // =============================================

  Future<void> addExam({
    required String titolo,
    required String courseId,
    required DateTime data,
    required String tipologia,
    String priorita = 'media',
    String stato = 'programmato',
    int? voto,
    String? note,
  }) async {
    final newExam = Exam(
      id: _uuid.v4(),
      titolo: titolo,
      courseId: courseId,
      data: data,
      tipologia: tipologia,
      priorita: priorita,
      stato: stato,
      voto: voto,
      note: note,
    );

    await _db.insertExam(newExam);
    _exams.add(newExam);
    notifyListeners();
  }

  Future<void> updateExam(Exam exam) async {
    await _db.updateExam(exam);
    int index = _exams.indexWhere((e) => e.id == exam.id);
    if (index != -1) {
      _exams[index] = exam;
      notifyListeners();
    }
  }

  Future<void> deleteExam(String id) async {
    await _db.deleteExam(id);
    _exams.removeWhere((e) => e.id == id);
    // Rimuovi sessioni e task collegati
    _studySessions.removeWhere((s) => s.examId == id);
    _tasks.removeWhere((t) => t.examId == id);
    notifyListeners();
  }

  Exam? getExamById(String id) {
    try {
      return _exams.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Exam> getExamsByCourse(String courseId) {
    return _exams.where((e) => e.courseId == courseId).toList();
  }

  // =============================================
  // ========== CRUD SESSIONI STUDIO =============
  // =============================================

  Future<void> addStudySession({
    required String titolo,
    String? courseId,
    String? examId,
    required DateTime data,
    required int durataPianificata,
    int? durataEffettiva,
    bool completata = false,
    String tipo = 'studio',
  }) async {
    final newSession = StudySession(
      id: _uuid.v4(),
      titolo: titolo,
      courseId: courseId,
      examId: examId,
      data: data,
      durataPianificata: durataPianificata,
      durataEffettiva: durataEffettiva,
      completata: completata,
      tipo: tipo,
    );

    await _db.insertStudySession(newSession);
    _studySessions.add(newSession);
    notifyListeners();
  }

  Future<void> updateStudySession(StudySession session) async {
    await _db.updateStudySession(session);
    int index = _studySessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      _studySessions[index] = session;
      notifyListeners();
    }
  }

  Future<void> deleteStudySession(String id) async {
    await _db.deleteStudySession(id);
    _studySessions.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // ========== FUNZIONE SPECIALE POMODORO =======
  
  /// Salva la sessione di studio derivata dal Timer Pomodoro 
  /// e aggiorna il tempo effettivo della Task nel database
  Future<void> savePomodoroSession({
    required String titolo,
    String? courseId,
    String? examId,
    required String taskId, // IMPORTANTE: L'ID della Task che stavamo studiando
    required int durataEffettiva,
    String tipo = 'pomodoro',
  }) async {
    // 1. Crea l'oggetto sessione
    final newSession = StudySession(
      id: _uuid.v4(),
      titolo: titolo,
      courseId: courseId,
      examId: examId,
      data: DateTime.now(),
      durataPianificata: durataEffettiva, // Nel pomodoro coincidono
      durataEffettiva: durataEffettiva,
      completata: true, // Il timer ha finito
      tipo: tipo,
    );

    // 2. Chiama la TRANSAZIONE SQL nel DatabaseHelper
    await _db.saveSessionAndUpdateTaskTime(newSession, taskId);

    // 3. Ricarica i dati dal DB per aggiornare tutta l'app 
    // (così la task mostrerà subito i minuti aggiornati!)
    await loadData();
  }

  StudySession? getStudySessionById(String id) {
    try {
      return _studySessions.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  List<StudySession> getStudySessionsByCourse(String courseId) {
    return _studySessions.where((s) => s.courseId == courseId).toList();
  }

  List<StudySession> getStudySessionsByDate(DateTime date) {
    return _studySessions.where((s) =>
      s.data.year == date.year &&
      s.data.month == date.month &&
      s.data.day == date.day
    ).toList();
  }

  // =============================================
  // ========== CRUD TASK ========================
  // =============================================

  Future<void> addTask({
    required String titolo,
    String? descrizione,
    String? courseId,
    String? examId,
    DateTime? scadenza,
    String priorita = 'media',
    bool completata = false,
    int? tempoStimato,
    int? tempoEffettivo,
    String? note,
  }) async {
    final newTask = Task(
      id: _uuid.v4(),
      titolo: titolo,
      descrizione: descrizione,
      courseId: courseId,
      examId: examId,
      scadenza: scadenza,
      priorita: priorita,
      completata: completata,
      tempoStimato: tempoStimato,
      tempoEffettivo: tempoEffettivo,
      note: note,
    );

    await _db.insertTask(newTask);
    _tasks.add(newTask);
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    await _db.updateTask(task);
    int index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  Future<void> toggleTaskCompletion(String taskId) async {
    final task = getTaskById(taskId);
    if (task != null) {
      final updatedTask = task.copyWith(completata: !task.completata);
      await updateTask(updatedTask);
    }
  }

  Future<void> deleteTask(String id) async {
    await _db.deleteTask(id);
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Task? getTaskById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  List<Task> getTasksByCourse(String courseId) {
    return _tasks.where((t) => t.courseId == courseId).toList();
  }

  List<Task> getPendingTasks() {
    return _tasks.where((t) => !t.completata).toList();
  }

  List<Task> getCompletedTasks() {
    return _tasks.where((t) => t.completata).toList();
  }

  // =============================================
  // ========== STATISTICHE ======================
  // =============================================

  int get totalCourses => _courses.length;
  int get activeCourses => _courses.where((c) => c.stato != 'superato').length;
  int get passedCourses => _courses.where((c) => c.isSuperato).length;

  int get totalExams => _exams.length;
  int get upcomingExams => _exams.where((e) => !e.isPassato && e.stato == 'programmato').length;
  int get completedExams => _exams.where((e) => e.isCompletato).length;

  int get totalTasks => _tasks.length;
  int get pendingTasks => _tasks.where((t) => !t.completata).length;
  int get completedTasksCount => _tasks.where((t) => t.completata).length;

  int get totalCfu => _courses.fold(0, (sum, c) => sum + c.cfu);
  int get earnedCfu => _courses.where((c) => c.isSuperato).fold(0, (sum, c) => sum + c.cfu);

  // Media ponderata dei voti
  double get weightedAverage {
    final passedWithGrade = _courses.where((c) => c.isSuperato && c.votoOttenuto != null);
    if (passedWithGrade.isEmpty) return 0.0;

    double totalWeighted = passedWithGrade.fold(0.0, (sum, c) => sum + (c.votoOttenuto! * c.cfu));
    int totalCfu = passedWithGrade.fold(0, (sum, c) => sum + c.cfu);

    return totalCfu > 0 ? totalWeighted / totalCfu : 0.0;
  }

  // Voto di laurea stimato
  double get estimatedGraduationGrade {
    return (weightedAverage / 30) * 110;
  }

  // Ore di studio totali (completate)
  int get totalStudyHours {
    return _studySessions
        .where((s) => s.completata && s.durataEffettiva != null)
        .fold(0, (sum, s) => sum + s.durataEffettiva!) ~/ 60;
  }

  // =============================================
  // ========== SUGGERITORE AUTOMATICO ===========
  // =============================================

  /// Getter intelligente per suggerimenti automatici
  /// Filtra corsi non superati con esami imminenti
  List<String> get suggerimentiAutomatici {
    final suggerimenti = <String>[];
    final oggi = DateTime.now();
    final scadenzaCritica = oggi.add(const Duration(days: 14));

    // 1. Trova esami imminenti di corsi non superati
    final esamiImminenti = _exams.where((e) {
      final course = getCourseById(e.courseId);
      if (course == null || course.isSuperato) return false;
      return e.data.isAfter(oggi) &&
             e.data.isBefore(scadenzaCritica) &&
             e.stato == 'programmato';
    }).toList();

    // 2. Ordina per data
    esamiImminenti.sort((a, b) => a.data.compareTo(b.data));

    // 3. Genera suggerimenti
    for (final esame in esamiImminenti.take(3)) {
      final course = getCourseById(esame.courseId);
      if (course == null) continue;

      final giorniMancanti = esame.data.difference(oggi).inDays;

      if (giorniMancanti <= 3) {
        suggerimenti.add('🚨 URGENZA: Fai una simulazione per ${course.nome}!');
      } else if (giorniMancanti <= 7) {
        suggerimenti.add('📚 Ripasso intensivo consigliato per ${course.nome}');
      } else {
        suggerimenti.add('✏️ Inizia gli esercizi per ${course.nome}');
      }
    }

    // 4. Suggerimenti per task in scadenza
    final taskInScadenza = _tasks.where((t) => t.isInScadenza && !t.completata).toList();
    for (final task in taskInScadenza.take(2)) {
      suggerimenti.add('⏰ Scadenza vicina: ${task.titolo}');
    }

    // 5. Messaggio base se nessun suggerimento
    if (suggerimenti.isEmpty && _courses.isNotEmpty) {
      suggerimenti.add('✅ Ottimo lavoro! Nessun esame imminente.');
    }

    return suggerimenti;
  }

  // =============================================
  // ========== UTILITY ==========================
  // =============================================

  /// Reset completo del database (per debug)
  Future<void> resetDatabase() async {
    await _db.deleteDatabase();
    _courses = [];
    _exams = [];
    _studySessions = [];
    _tasks = [];
    notifyListeners();
  }
}
