class Exam {
  final String id;
  final String titolo;
  final String courseId; // FK verso Course 
  final DateTime data;
  final String tipologia; // scritto , orale, intercorso, consegna, progetto
  final String priorita; // alta, media, bassa
  final String stato; // programmato, completato, annullato
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

  bool get isPassato => data.isBefore(DateTime.now());
  bool get isCompletato => stato == 'completato';
  bool get isImminente {
    if (isCompletato || stato == 'annullato') return false;
    final giorniRimasti = data.difference(DateTime.now()).inDays;
    return giorniRimasti >= 0 && giorniRimasti <= 7;
  }

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
    bool clearVoto = false,
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
      voto: clearVoto ? null : (voto ?? this.voto), 
      note: note ?? this.note,
    );
  }
}