import 'package:hive/hive.dart';

part 'joint_config.g.dart';

@HiveType(typeId: 1)
class JointConfig extends HiveObject {
  @HiveField(0)
  int index;

  @HiveField(1)
  int pinNumber;

  @HiveField(2)
  int minAngle;

  @HiveField(3)
  int maxAngle;

  @HiveField(4)
  int servoMin;

  @HiveField(5)
  int servoMax;

  @HiveField(6, defaultValue: -1)
  int defaultAngle;

  JointConfig({
    required this.index,
    required this.pinNumber,
    this.minAngle = 0,
    this.maxAngle = 180,
    this.servoMin = 150,
    this.servoMax = 600,
    this.defaultAngle = -1,
  });
}
