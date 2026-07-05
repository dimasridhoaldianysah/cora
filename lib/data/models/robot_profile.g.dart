// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'robot_profile.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RobotProfileAdapter extends TypeAdapter<RobotProfile> {
  @override
  final int typeId = 0;

  @override
  RobotProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RobotProfile(
      id: fields[0] as String,
      name: fields[1] as String,
      board: fields[2] as String,
      jointCount: fields[3] as int,
      pins: (fields[4] as List).cast<int>(),
      driverType: fields[5] as String,
      isActive: fields[6] as bool,
      joints: (fields[7] as List).cast<JointConfig>(),
    );
  }

  @override
  void write(BinaryWriter writer, RobotProfile obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.board)
      ..writeByte(3)
      ..write(obj.jointCount)
      ..writeByte(4)
      ..write(obj.pins)
      ..writeByte(5)
      ..write(obj.driverType)
      ..writeByte(6)
      ..write(obj.isActive)
      ..writeByte(7)
      ..write(obj.joints);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RobotProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
