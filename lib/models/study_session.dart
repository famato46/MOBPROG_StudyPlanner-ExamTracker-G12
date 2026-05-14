class StudySession {
  final String id;
  final String titolo;
  final String? courseId; // FK facoltativa verso Course
  final String? examId; // FK facoltativa verso Exam
  final DateTime data;
  final int durataPianificata; // Minuti previsti
  final int? durataEffettiva; // Minuti effettivi (da timer Pomodoro)
  final bool completata;
  final String tipo; // 'studio' | 'ripasso' | 'esercitazione'

  const StudySession({
    required this.id,
    required this.titolo,
    this.courseId,
    this.examId,
    required this.data,
    required this.durataPianificata,
    this.durataEffettiva,
    required this.completata,
    required this.tipo,
  });

  // Conversione da Map (dal database)
  factory StudySession.fromMap(Map<String, dynamic> map) {
    return StudySession(
      id: map['id'] as String,
      titolo: map['titolo'] as String,
      courseId: map['courseId'] as String?,
      examId: map['examId'] as String?,
      data: DateTime.parse(map['data'] as String),
      durataPianificata: map['durataPianificata'] as int,
      durataEffettiva: map['durataEffettiva'] as int?,
      completata: (map['completata'] as int) == 1,
      tipo: map['tipo'] as String,
    );
  }

  // Conversione a Map (per il database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titolo': titolo,
      'courseId': courseId,
      'examId': examId,
      'data': data.toIso8601String(),
      'durataPianificata': durataPianificata,
      'durataEffettiva': durataEffettiva,
      'completata': completata ? 1 : 0,
      'tipo': tipo,
    };
  }

  // Metodo copyWith
  StudySession copyWith({
    String? id,
    String? titolo,
    String? courseId,
    String? examId,
    DateTime? data,
    int? durataPianificata,
    int? durataEffettiva,
    bool? completata,
    String? tipo,
  }) {
    return StudySession(
      id: id ?? this.id,
      titolo: titolo ?? this.titolo,
      courseId: courseId ?? this.courseId,
      examId: examId ?? this.examId,
      data: data ?? this.data,
      durataPianificata: durataPianificata ?? this.durataPianificata,
      durataEffettiva: durataEffettiva ?? this.durataEffettiva,
      completata: completata ?? this.completata,
      tipo: tipo ?? this.tipo,
    );
  }

  // Helper per verificare se è oggi
  bool get isOggi {
    final oggi = DateTime.now();
    return data.year == oggi.year &&
           data.month == oggi.month &&
           data.day == oggi.day;
  }
  
  // Helper per ottenere la differenza tra pianificato ed effettivo
  int? get differenzaTempo {
    if (durataEffettiva == null) return null;
    return durataEffettiva! - durataPianificata;
  }
}
