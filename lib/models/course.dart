import 'package:hive/hive.dart';
part 'course.g.dart';

@HiveType(typeId: 0)
class Course extends HiveObject {
  @HiveField(0) final String id;
  @HiveField(1) final String nome;
  @HiveField(2) final String docente;
  @HiveField(3) final int cfu;
  @HiveField(4) final String semestre;
  @HiveField(5) String stato; // 'da_iniziare'|'in_corso'|'completato'|'superato'
  @HiveField(6) int? voto;
  @HiveField(7) String? note;

  Course({
    required this.id,
    required this.nome,
    required this.docente,
    required this.cfu,
    required this.semestre,
    this.stato = 'da_iniziare',
    this.voto,
    this.note,
  });
}