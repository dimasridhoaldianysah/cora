// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'joint_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JointConfigAdapter extends TypeAdapter<JointConfig> {
  @override
  final int typeId = 1;

  @override
  JointConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JointConfig(
      index: fields[0] as int,
      pinNumber: fields[1] as int,
      minAngle: fields[2] as int,
      maxAngle: fields[3] as int,
      servoMin: fields[4] as int,
      servoMax: fields[5] as int,
      defaultAngle: fields[6] == null ? -1 : fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, JointConfig obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.index)
      ..writeByte(1)
      ..write(obj.pinNumber)
      ..writeByte(2)
      ..write(obj.minAngle)
      ..writeByte(3)
      ..write(obj.maxAngle)
      ..writeByte(4)
      ..write(obj.servoMin)
      ..writeByte(5)
      ..write(obj.servoMax)
      ..writeByte(6)
      ..write(obj.defaultAngle);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JointConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
