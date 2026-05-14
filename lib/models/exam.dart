class Exam {
  final String id;
  final String titolo;
  final String courseId; // FK verso Course (obbligatorio)
  final DateTime data;
  final String tipologia; // 'esame' | 'appello' | 'consegna' | 'progetto'
  final String priorita; // 'alta' | 'media' | 'bassa'
  final String stato; // 'programmato' | 'completato' | 'annullato'
  final int? voto;
  final String? note;

  const Exam({
    required this.id,
    required this.titolo,
    required this.courseId,
    required this.data,
    required this.tipologia,
    required this.priorita,
    required this.stato,
    this.voto,
    this.note,
  });

  // Conversione da Map (dal database)
  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as String,
      titolo: map['titolo'] as String,
      courseId: map['courseId'] as String,
      data: DateTime.parse(map['data'] as String),
      tipologia: map['tipologia'] as String,
      priorita: map['priorita'] as String,
      stato: map['stato'] as String,
      voto: map['voto'] as int?,
      note: map['note'] as String?,
    );
  }

  // Conversione a Map (per il database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titolo': titolo,
      'courseId': courseId,
      'data': data.toIso8601String(),
      'tipologia': tipologia,
      'priorita': priorita,
      'stato': stato,
      'voto': voto,
      'note': note,
    };
  }

  // Metodo copyWith
  Exam copyWith({
    String? id,
    String? titolo,
    String? courseId,
    DateTime? data,
    String? tipologia,
    String? priorita,
    String? stato,
    int? voto,
    String? note,
  }) {
    return Exam(
      id: id ?? this.id,
      titolo: titolo ?? this.titolo,
      courseId: courseId ?? this.courseId,
      data: data ?? this.data,
      tipologia: tipologia ?? this.tipologia,
      priorita: priorita ?? this.priorita,
      stato: stato ?? this.stato,
      voto: voto ?? this.voto,
      note: note ?? this.note,
    );
  }

  // Helper per verificare se è completato
  bool get isCompletato => stato == 'completato';
  
  // Helper per verificare se è imminente (entro 7 giorni)
  bool get isImminente {
    final oggi = DateTime.now();
    final differenza = data.difference(oggi).inDays;
    return differenza >= 0 && differenza <= 7;
  }
  
  // Helper per verificare se è passato
  bool get isPassato => data.isBefore(DateTime.now());
}
