import 'package:hive/hive.dart';
part 'study_session.g.dart';

@HiveType(typeId: 2)
class StudySession extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String titolo;
  @HiveField(2) final String? courseId;
  @HiveField(3) final String? examId;
  @HiveField(4) final DateTime data;
  @HiveField(5) final int durataPianificata; // minuti
  @HiveField(6) final int? durataEffettiva;
  @HiveField(7)final bool completata;
  @HiveField(8) final String tipo; // 'studio'|'ripasso'|'esercitazione'

  StudySession({
    required this.id,
    required this.titolo,
    required this.data,
    required this.durataPianificata,
    required this.tipo,
    this.courseId,
    this.examId,
    this.durataEffettiva,
    this.completata = false,
  });
}