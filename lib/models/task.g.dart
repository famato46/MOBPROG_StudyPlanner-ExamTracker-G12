// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 3;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      titolo: fields[1] as String,
      priorita: fields[6] as String,
      descrizione: fields[2] as String?,
      courseId: fields[3] as String?,
      examId: fields[4] as String?,
      scadenza: fields[5] as DateTime?,
      completata: fields[7] as bool,
      tempoStimato: fields[8] as int?,
      tempoEffettivo: fields[9] as int?,
      note: fields[10] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.titolo)
      ..writeByte(2)
      ..write(obj.descrizione)
      ..writeByte(3)
      ..write(obj.courseId)
      ..writeByte(4)
      ..write(obj.examId)
      ..writeByte(5)
      ..write(obj.scadenza)
      ..writeByte(6)
      ..write(obj.priorita)
      ..writeByte(7)
      ..write(obj.completata)
      ..writeByte(8)
      ..write(obj.tempoStimato)
      ..writeByte(9)
      ..write(obj.tempoEffettivo)
      ..writeByte(10)
      ..write(obj.note);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
