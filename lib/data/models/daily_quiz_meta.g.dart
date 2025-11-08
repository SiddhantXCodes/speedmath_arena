// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_quiz_meta.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyQuizMetaAdapter extends TypeAdapter<DailyQuizMeta> {
  @override
  final int typeId = 11;

  @override
  DailyQuizMeta read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyQuizMeta(
      date: fields[0] as String,
      totalQuestions: fields[1] as int,
      difficulty: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DailyQuizMeta obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.totalQuestions)
      ..writeByte(2)
      ..write(obj.difficulty);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyQuizMetaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
