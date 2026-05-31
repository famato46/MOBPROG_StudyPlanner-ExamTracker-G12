class Task {
  final String id;
  final String titolo;
  final String? descrizione;
  final String? courseId; // FK facoltativa verso Course
  final String? examId; // FK facoltativa verso Exam
  final DateTime? scadenza;
  final String priorita; // alta, media, bassa
  final bool completata;
  final int? tempoStimato; // Minuti previsti
  final int? tempoEffettivo; // Minuti effettivi impiegati
  final String? note;

  const Task({
    required this.id,
    required this.titolo,
    this.descrizione,
    this.courseId,
    this.examId,
    this.scadenza,
    required this.priorita,
    required this.completata,
    this.tempoStimato,
    this.tempoEffettivo,
    this.note,
  });

  // Conversione da Map (dal database)
  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'] as String,
      titolo: map['titolo'] as String,
      descrizione: map['descrizione'] as String?,
      courseId: map['courseId'] as String?,
      examId: map['examId'] as String?,
      scadenza: map['scadenza'] != null 
          ? DateTime.parse(map['scadenza'] as String)
          : null,
      priorita: map['priorita'] as String,
      completata: (map['completata'] as int) == 1,
      tempoStimato: map['tempoStimato'] as int?,
      tempoEffettivo: map['tempoEffettivo'] as int?,
      note: map['note'] as String?,
    );
  }

  // Conversione a Map (per il database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titolo': titolo,
      'descrizione': descrizione,
      'courseId': courseId,
      'examId': examId,
      'scadenza': scadenza?.toIso8601String(),
      'priorita': priorita,
      'completata': completata ? 1 : 0,
      'tempoStimato': tempoStimato,
      'tempoEffettivo': tempoEffettivo,
      'note': note,
    };
  }

  // Metodo copyWith
  Task copyWith({
    String? id,
    String? titolo,
    String? descrizione,
    String? courseId,
    String? examId,
    DateTime? scadenza,
    String? priorita,
    bool? completata,
    int? tempoStimato,
    int? tempoEffettivo,
    String? note,
  }) {
    return Task(
      id: id ?? this.id,
      titolo: titolo ?? this.titolo,
      descrizione: descrizione ?? this.descrizione,
      courseId: courseId ?? this.courseId,
      examId: examId ?? this.examId,
      scadenza: scadenza ?? this.scadenza,
      priorita: priorita ?? this.priorita,
      completata: completata ?? this.completata,
      tempoStimato: tempoStimato ?? this.tempoStimato,
      tempoEffettivo: tempoEffettivo ?? this.tempoEffettivo,
      note: note ?? this.note,
    );
  }

  // Helper per verificare se è in scadenza (entro 3 giorni)
  bool get isInScadenza {
    if (scadenza == null) return false;
    final oggi = DateTime.now();
    final differenza = scadenza!.difference(oggi).inDays;
    return differenza >= 0 && differenza <= 3;
  }
  
  // Helper per verificare se è scaduta
  bool get isScaduta {
    if (scadenza == null) return false;
    return scadenza!.isBefore(DateTime.now()) && !completata;
  }
  
}
