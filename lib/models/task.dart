import 'package:hive/hive.dart';
part 'task.g.dart';

@HiveType(typeId: 3)
class Task extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String titolo;
  @HiveField(2) String? descrizione;
  @HiveField(3) String? courseId;
  @HiveField(4) String? examId;
  @HiveField(5) DateTime? scadenza;
  @HiveField(6) String priorita; // 'alta'|'media'|'bassa'
  @HiveField(7) bool completata;
  @HiveField(8) int? tempoStimato;
  @HiveField(9) int? tempoEffettivo;
  @HiveField(10) String? note;

  Task({
    required this.id,
    required this.titolo,
    required this.priorita,
    this.descrizione,
    this.courseId,
    this.examId,
    this.scadenza,
    this.completata = false,
    this.tempoStimato,
    this.tempoEffettivo,
    this.note,
  });
}