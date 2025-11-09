// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'practice_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PracticeLogAdapter extends TypeAdapter<PracticeLog> {
  @override
  final int typeId = 0;

  @override
  PracticeLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PracticeLog(
      date: fields[0] as DateTime,
      topic: fields[1] as String,
      category: fields[2] as String,
      correct: fields[3] as int,
      incorrect: fields[4] as int,
      score: fields[5] as int,
      total: fields[6] as int,
      avgTime: fields[7] as double,
      timeSpentSeconds: fields[8] as int,
      questions: (fields[9] as List)
          .map((dynamic e) => (e as Map).cast<String, dynamic>())
          .toList(),
      userAnswers: (fields[10] as Map).cast<int, String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PracticeLog obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.topic)
      ..writeByte(2)
      ..write(obj.category)
      ..writeByte(3)
      ..write(obj.correct)
      ..writeByte(4)
      ..write(obj.incorrect)
      ..writeByte(5)
      ..write(obj.score)
      ..writeByte(6)
      ..write(obj.total)
      ..writeByte(7)
      ..write(obj.avgTime)
      ..writeByte(8)
      ..write(obj.timeSpentSeconds)
      ..writeByte(9)
      ..write(obj.questions)
      ..writeByte(10)
      ..write(obj.userAnswers);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PracticeLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
