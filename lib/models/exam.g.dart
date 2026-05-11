// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exam.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExamAdapter extends TypeAdapter<Exam> {
  @override
  final int typeId = 1;

  @override
  Exam read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exam(
      id: fields[0] as String,
      titolo: fields[1] as String,
      courseId: fields[2] as String,
      data: fields[3] as DateTime,
      tipologia: fields[4] as String,
      priorita: fields[5] as String,
      stato: fields[6] as String,
      voto: fields[7] as int?,
      note: fields[8] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Exam obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titolo)
      ..writeByte(2)
      ..write(obj.courseId)
      ..writeByte(3)
      ..write(obj.data)
      ..writeByte(4)
      ..write(obj.tipologia)
      ..writeByte(5)
      ..write(obj.priorita)
      ..writeByte(6)
      ..write(obj.stato)
      ..writeByte(7)
      ..write(obj.voto)
      ..writeByte(8)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExamAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
