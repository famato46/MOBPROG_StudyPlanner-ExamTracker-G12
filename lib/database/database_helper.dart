import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course.dart';
import '../models/exam.dart';
import '../models/study_session.dart';
import '../models/task.dart';

// DatabaseHelper - Pattern Singleton per gestire SQLite
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // INIZIALIZZAZIONE DATABASE 
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'unipath.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON;'); // per evitare esami orfani al riavvio
      },
    );
  }

  // CREAZIONE TABELLE 
  Future<void> _onCreate(Database db, int version) async {
    // Tabella Corsi
    await db.execute('''
      CREATE TABLE courses (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        docente TEXT NOT NULL,
        cfu INTEGER NOT NULL,
        semestre TEXT NOT NULL,
        stato TEXT NOT NULL,
        votoOttenuto INTEGER,
        votoDesiderato INTEGER,
        note TEXT,
        materialeAssociato TEXT
      )
    ''');

    // Tabella Esami
    await db.execute('''
      CREATE TABLE exams (
        id TEXT PRIMARY KEY,
        titolo TEXT NOT NULL,
        courseId TEXT NOT NULL,
        data TEXT NOT NULL,
        tipologia TEXT NOT NULL,
        priorita TEXT NOT NULL,
        stato TEXT NOT NULL,
        voto INTEGER,
        note TEXT,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE
      )
    ''');

    // Tabella Sessioni di Studio
    await db.execute('''
      CREATE TABLE study_sessions (
        id TEXT PRIMARY KEY,
        titolo TEXT NOT NULL,
        courseId TEXT,
        examId TEXT,
        data TEXT NOT NULL,
        durataPianificata INTEGER NOT NULL,
        durataEffettiva INTEGER,
        completata INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE,
        FOREIGN KEY (examId) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''');

    // Tabella Attività
    await db.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        titolo TEXT NOT NULL,
        descrizione TEXT,
        courseId TEXT,
        examId TEXT,
        scadenza TEXT,
        priorita TEXT NOT NULL,
        completata INTEGER NOT NULL,
        tempoStimato INTEGER,
        tempoEffettivo INTEGER,
        note TEXT,
        FOREIGN KEY (courseId) REFERENCES courses (id) ON DELETE CASCADE,
        FOREIGN KEY (examId) REFERENCES exams (id) ON DELETE CASCADE
      )
    ''');
  }


  // CRUD CORSI 
  Future<int> insertCourse(Course course) async {
    Database db = await database;
    return await db.insert('courses', course.toMap());
  }

  Future<List<Course>> getCourses() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('courses');
    return List.generate(maps.length, (i) => Course.fromMap(maps[i]));
  }

  Future<int> updateCourse(Course course) async {
    Database db = await database;
    return await db.update(
      'courses',
      course.toMap(),
      where: 'id = ?',
      whereArgs: [course.id],
    );
  }

  Future<int> deleteCourse(String id) async {
    Database db = await database;
    return await db.delete('courses', where: 'id = ?', whereArgs: [id]);
  }

  // CRUD ESAMI 
  Future<int> insertExam(Exam exam) async {
    Database db = await database;
    return await db.insert('exams', exam.toMap());
  }

  Future<List<Exam>> getExams() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('exams', orderBy: 'data ASC');
    return List.generate(maps.length, (i) => Exam.fromMap(maps[i]));
  }

  Future<int> updateExam(Exam exam) async {
    Database db = await database;
    return await db.update(
      'exams',
      exam.toMap(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }

  Future<int> deleteExam(String id) async {
    Database db = await database;
    return await db.delete('exams', where: 'id = ?', whereArgs: [id]);
  }


  // CRUD SESSIONI 
  Future<int> insertStudySession(StudySession session) async {
    Database db = await database;
    return await db.insert('study_sessions', session.toMap());
  }

  Future<List<StudySession>> getStudySessions() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('study_sessions', orderBy: 'data DESC');
    return List.generate(maps.length, (i) => StudySession.fromMap(maps[i]));
  }


  Future<int> updateStudySession(StudySession session) async {
    Database db = await database;
    return await db.update(
      'study_sessions',
      session.toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<int> deleteStudySession(String id) async {
    Database db = await database;
    return await db.delete('study_sessions', where: 'id = ?', whereArgs: [id]);
  }

 
  // CRUD TASK 
  Future<int> insertTask(Task task) async {
    Database db = await database;
    return await db.insert('tasks', task.toMap());
  }

  Future<List<Task>> getTasks() async {
    Database db = await database;
    List<Map<String, dynamic>> maps = await db.query('tasks');
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }

  Future<int> updateTask(Task task) async {
    Database db = await database;
    return await db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> deleteTask(String id) async {
    Database db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }


  // UTILITY 

  // Elimina tutto il database (per debug)
  Future<void> deleteDatabase() async {
    String path = join(await getDatabasesPath(), 'unipath.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }

  // TRANSAZIONE POMODORO 
 
  // Salva una sessione di studio e aggiorna il tempo effettivo della Task associata
  Future<void> saveSessionAndUpdateTaskTime(StudySession session, String taskId) async {
    Database db = await database;
    
    // Usiamo una transaction: o fa entrambe le cose, o non ne fa nessuna (sicurezza dei dati)
    await db.transaction((txn) async {
      // Inserisce la sessione nello storico
      await txn.insert('study_sessions', session.toMap());

      // Legge la task corrente dal database
      List<Map<String, dynamic>> taskMap = await txn.query(
        'tasks',
        where: 'id = ?',
        whereArgs: [taskId],
      );

      if (taskMap.isNotEmpty) {
        Task currentTask = Task.fromMap(taskMap.first);
        
        // Calcola il nuovo tempo totale
        int nuovoTempoEffettivo = (currentTask.tempoEffettivo ?? 0) + (session.durataEffettiva ?? 0);

        // Aggiorna la task con il nuovo tempo effettivo
        await txn.update(
          'tasks',
          {'tempoEffettivo': nuovoTempoEffettivo},
          where: 'id = ?',
          whereArgs: [taskId],
        );
      }
    });
  }
}
