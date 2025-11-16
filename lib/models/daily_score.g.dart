// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_score.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyScoreAdapter extends TypeAdapter<DailyScore> {
  @override
  final int typeId = 6;

  @override
  DailyScore read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyScore(
      date: fields[0] as DateTime,
      score: fields[1] as int,
      totalQuestions: fields[2] as int,
      timeTakenSeconds: fields[3] as int,
      isRanked: fields[4] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, DailyScore obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.date)
      ..writeByte(1)
      ..write(obj.score)
      ..writeByte(2)
      ..write(obj.totalQuestions)
      ..writeByte(3)
      ..write(obj.timeTakenSeconds)
      ..writeByte(4)
      ..write(obj.isRanked);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyScoreAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
