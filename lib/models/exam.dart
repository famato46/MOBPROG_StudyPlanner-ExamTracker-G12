import 'package:hive/hive.dart';
part 'exam.g.dart';

@HiveType(typeId: 1)
class Exam extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String titolo;
  @HiveField(2) final String courseId;
  @HiveField(3) final DateTime data;
  @HiveField(4) final String tipologia; // 'esame'|'consegna'|'appello'|'progetto'
  @HiveField(5) String priorita;        // 'alta'|'media'|'bassa'
  @HiveField(6) String stato;           // 'programmato'|'completato'|'annullato'
  @HiveField(7) int? voto;
  @HiveField(8) String? note;

  Exam({
    required this.id,
    required this.titolo,
    required this.courseId,
    required this.data,
    required this.tipologia,
    this.priorita = 'media',
    this.stato = 'programmato',
    this.voto,
    this.note,
  });
}