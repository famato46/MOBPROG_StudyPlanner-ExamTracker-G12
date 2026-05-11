// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudySessionAdapter extends TypeAdapter<StudySession> {
  @override
  final int typeId = 2;

  @override
  StudySession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StudySession(
      id: fields[0] as String,
      titolo: fields[1] as String,
      data: fields[4] as DateTime,
      durataPianificata: fields[5] as int,
      tipo: fields[8] as String,
      courseId: fields[2] as String?,
      examId: fields[3] as String?,
      durataEffettiva: fields[6] as int?,
      completata: fields[7] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, StudySession obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titolo)
      ..writeByte(2)
      ..write(obj.courseId)
      ..writeByte(3)
      ..write(obj.examId)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.durataPianificata)
      ..writeByte(6)
      ..write(obj.durataEffettiva)
      ..writeByte(7)
      ..write(obj.completata)
      ..writeByte(8)
      ..write(obj.tipo);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudySessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
