import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/database_helper.dart';
import '../models/course.dart';
import '../models/exam.dart';
import '../models/study_session.dart';
import '../models/task.dart';

// PlannerProvider: gestisce lo stato 
class PlannerProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  // STATE (Liste caricate dal DB)
  List<Course> _courses = [];
  List<Exam> _exams = [];
  List<StudySession> _studySessions = [];
  List<Task> _tasks = [];

  bool _isLoading = false;

  // GETTERS  
  List<Course> get courses => _courses;
  List<Exam> get exams => _exams;
  List<StudySession> get studySessions => _studySessions;
  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  // COSTRUTTORE 
  PlannerProvider() {
    loadData();
  }

  // CARICAMENTO DATI 
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


  // CRUD CORSI 
  Future<void> addCourse({
    required String nome,
    required String docente,
    required int cfu,
    required String semestre,
    String stato = 'da_iniziare',
    int? votoDesiderato,
    int? votoOttenuto,
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
      votoOttenuto: votoOttenuto,
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


  // CRUD ESAMI 
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
    final index = _exams.indexWhere((e) => e.id == exam.id);
    if (index != -1) {
      _exams[index] = exam;
      notifyListeners();
    }
  }

  Future<void> deleteExam(String id) async {
    await _db.deleteExam(id);
    _exams.removeWhere((e) => e.id == id);
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

  double? getAverageExamsGrade(String courseId) {
    final completedExams = _exams.where((e) => 
        e.courseId == courseId && 
        e.stato == 'completato' && 
        e.voto != null).toList();

    if (completedExams.isEmpty) return null;

    final sum = completedExams.fold<int>(0, (total, current) => total + current.voto!);
    return sum / completedExams.length;
  }


  // CRUD SESSIONI STUDIO 
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
    final index = _studySessions.indexWhere((s) => s.id == session.id);
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

  // FUNZIONI POMODORO
  Future<void> savePomodoroSession({
    required String titolo,
    String? courseId,
    String? examId,
    required String taskId,
    required int durataEffettiva,
    String tipo = 'pomodoro',
  }) async {
    final newSession = StudySession(
      id: _uuid.v4(),
      titolo: titolo,
      courseId: courseId,
      examId: examId,
      data: DateTime.now(),
      durataPianificata: durataEffettiva,
      durataEffettiva: durataEffettiva,
      completata: true,
      tipo: tipo,
    );

    await _db.saveSessionAndUpdateTaskTime(newSession, taskId);
    await loadData();
  }

  Future<void> savePausaSession({
    required int durataEffettiva,
  }) async {
    final newSession = StudySession(
      id: _uuid.v4(),
      titolo: 'Pausa Focus',
      data: DateTime.now(),
      durataPianificata: durataEffettiva,
      durataEffettiva: durataEffettiva,
      completata: true,
      tipo: 'pausa',
    );

    await _db.insertStudySession(newSession);
    _studySessions.add(newSession);
    notifyListeners();
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
    return _studySessions
        .where((s) =>
            s.data.year == date.year &&
            s.data.month == date.month &&
            s.data.day == date.day)
        .toList();
  }


  // CRUD TASK 
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
    final index = _tasks.indexWhere((t) => t.id == task.id);
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

  // STATISTICHE POMODORO 
  int get pomodoriCompletati => _studySessions
      .where((s) => s.completata && s.tipo == 'pomodoro')
      .length;

  int get pauseCompletate => _studySessions
      .where((s) => s.completata && s.tipo == 'pausa')
      .length;

  int get minutiTotaliFocus => _studySessions
      .where((s) => s.completata && s.tipo == 'pomodoro')
      .fold(0, (sum, s) => sum + (s.durataEffettiva ?? 0));

  // STATISTICHE GENERALI 
  int get totalCourses => _courses.length;
  int get activeCourses =>
      _courses.where((c) => c.stato != 'superato').length;
  int get passedCourses => _courses.where((c) => c.isSuperato).length;

  int get totalExams => _exams.length;
  int get upcomingExams {
    final oggi = DateTime.now();
    final oggiDate = DateTime(oggi.year, oggi.month, oggi.day);
    return _exams
        .where((e) =>
            e.stato == 'programmato' &&
            !DateTime(e.data.year, e.data.month, e.data.day)
                .isBefore(oggiDate))
        .length;
  }
  int get completedExams => _exams.where((e) => e.isCompletato).length;

  int get totalTasks => _tasks.length;
  int get pendingTasks => _tasks.where((t) => !t.completata).length;
  int get completedTasksCount => _tasks.where((t) => t.completata).length;

  int get totalCfu => _courses.fold(0, (sum, c) => sum + c.cfu);
  
  int get earnedCfu =>
      _courses.where((c) => c.stato == 'superato').fold(0, (sum, c) => sum + c.cfu);

  double get weightedAverage {
    double totalePonderato = 0;
    int totaleCfu = 0;

    for (var corso in _courses) {
      if (corso.stato == 'superato' && corso.votoOttenuto != null) {
        totalePonderato += corso.votoOttenuto! * corso.cfu;
        totaleCfu += corso.cfu;
      }
    }

    if (totaleCfu == 0) return 0.0;
    return totalePonderato / totaleCfu;
  }

  double get estimatedGraduationGrade {
    if (weightedAverage == 0.0) return 0.0;
    return (weightedAverage / 30) * 110;
  }

  // Serve a non contare le pause nel totale dello studio
  int get totalStudyHours {
    return _studySessions
            .where((s) => s.completata && s.durataEffettiva != null && s.tipo != 'pausa')
            .fold(0, (sum, s) => sum + s.durataEffettiva!) ~/
        60;
  }

  // SUGGERITORE AUTOMATICO 
  List<String> get suggerimentiAutomatici {
    final suggerimenti = <String>[];
    final oggi = DateTime.now();
    final scadenzaCritica = oggi.add(const Duration(days: 14));

    final esamiImminenti = <Exam>[];
    for (var esame in _exams) {
      final corso = getCourseById(esame.courseId);
      if (corso == null || corso.stato == 'superato') continue;
      if (esame.stato != 'programmato') continue;
      if (!esame.data.isAfter(oggi)) continue;
      if (!esame.data.isBefore(scadenzaCritica)) continue;
      esamiImminenti.add(esame);
    }

    esamiImminenti.sort((a, b) => a.data.compareTo(b.data));

    int contatore = 0;
    for (var esame in esamiImminenti) {
      if (contatore >= 3) break;
      final corso = getCourseById(esame.courseId);
      if (corso == null) continue;
      final giorniMancanti = esame.data.difference(oggi).inDays;
      if (giorniMancanti <= 3) {
        suggerimenti.add('URGENZA: Fai una simulazione per ${corso.nome}!');
      } else if (giorniMancanti <= 7) {
        suggerimenti.add('Ripasso intensivo consigliato per ${corso.nome}');
      } else {
        suggerimenti.add('Inizia gli esercizi per ${corso.nome}');
      }
      contatore++;
    }

    int taskContatore = 0;
    for (var task in _tasks) {
      if (taskContatore >= 2) break;
      if (task.isInScadenza && !task.completata) {
        suggerimenti.add('Scadenza vicina: ${task.titolo}');
        taskContatore++;
      }
    }

    if (suggerimenti.isEmpty && _courses.isNotEmpty) {
      suggerimenti.add('Ottimo lavoro! Nessun esame imminente.');
    }

    return suggerimenti;
  }

  // RESET DATABASE per testing
  Future<void> resetDatabase() async {
    await _db.deleteDatabase();
    _courses = [];
    _exams = [];
    _studySessions = [];
    _tasks = [];
    notifyListeners();
  }
}