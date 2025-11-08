// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_history.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class QuestionHistoryAdapter extends TypeAdapter<QuestionHistory> {
  @override
  final int typeId = 1;

  @override
  QuestionHistory read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return QuestionHistory(
      question: fields[0] as String,
      userAnswer: fields[1] as String,
      correctAnswer: fields[2] as String,
      isCorrect: fields[3] as bool,
      date: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, QuestionHistory obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.question)
      ..writeByte(1)
      ..write(obj.userAnswer)
      ..writeByte(2)
      ..write(obj.correctAnswer)
      ..writeByte(3)
      ..write(obj.isCorrect)
      ..writeByte(4)
      ..write(obj.date);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuestionHistoryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
