class Course {
  final String id;
  final String nome;
  final String docente;
  final int cfu;
  final String semestre;
  final String stato; // 'da_iniziare' | 'in_corso' | 'da_ripassare' | 'completato' | 'superato'
  final int? votoOttenuto;
  final int? votoDesiderato;
  final String? note;
  final String? materialeAssociato;

  const Course({
    required this.id,
    required this.nome,
    required this.docente,
    required this.cfu,
    required this.semestre,
    required this.stato,
    this.votoOttenuto,
    this.votoDesiderato,
    this.note,
    this.materialeAssociato,
  });

  // Conversione da Map (dal database)
  factory Course.fromMap(Map<String, dynamic> map) {
    return Course(
      id: map['id'] as String,
      nome: map['nome'] as String,
      docente: map['docente'] as String,
      cfu: map['cfu'] as int,
      semestre: map['semestre'] as String,
      stato: map['stato'] as String,
      votoOttenuto: map['votoOttenuto'] as int?,
      votoDesiderato: map['votoDesiderato'] as int?,
      note: map['note'] as String?,
      materialeAssociato: map['materialeAssociato'] as String?,
    );
  }

  // Conversione a Map (per il database)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nome': nome,
      'docente': docente,
      'cfu': cfu,
      'semestre': semestre,
      'stato': stato,
      'votoOttenuto': votoOttenuto,
      'votoDesiderato': votoDesiderato,
      'note': note,
      'materialeAssociato': materialeAssociato,
    };
  }

  // Metodo copyWith per modifiche immutabili.
  // Per i campi nullable usiamo un sentinel Object() come default
  // così distinguiamo "parametro omesso" (mantieni il valore attuale)
  // da "passato null" (azzera il campo). Senza questo, quando si
  // cambia stato da 'superato' ad altro e si salva con votoOttenuto:null,
  // il ?? mantiene il voto precedente invece di azzerarlo.
  static const _unset = Object();

  Course copyWith({
    String? id,
    String? nome,
    String? docente,
    int? cfu,
    String? semestre,
    String? stato,
    Object? votoOttenuto = _unset,
    Object? votoDesiderato = _unset,
    Object? note = _unset,
    Object? materialeAssociato = _unset,
  }) {
    return Course(
      id: id ?? this.id,
      nome: nome ?? this.nome,
      docente: docente ?? this.docente,
      cfu: cfu ?? this.cfu,
      semestre: semestre ?? this.semestre,
      stato: stato ?? this.stato,
      votoOttenuto: identical(votoOttenuto, _unset)
          ? this.votoOttenuto
          : votoOttenuto as int?,
      votoDesiderato: identical(votoDesiderato, _unset)
          ? this.votoDesiderato
          : votoDesiderato as int?,
      note: identical(note, _unset) ? this.note : note as String?,
      materialeAssociato: identical(materialeAssociato, _unset)
          ? this.materialeAssociato
          : materialeAssociato as String?,
    );
  }

  // Helper per verificare se è superato
  bool get isSuperato => stato == 'superato';
  
  // Helper per verificare se ha un voto
  bool get hasVoto => votoOttenuto != null;
}