import 'package:hive/hive.dart';
import 'joint_config.dart';

part 'robot_profile.g.dart';

@HiveType(typeId: 0)
class RobotProfile extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String board; // 'uno' | 'nano' | 'esp32'

  @HiveField(3)
  int jointCount; // 1-6

  @HiveField(4)
  List<int> pins;

  @HiveField(5)
  String driverType; // 'pca9685' | 'direct'

  @HiveField(6)
  bool isActive;

  @HiveField(7)
  List<JointConfig> joints;

  RobotProfile({
    required this.id,
    required this.name,
    required this.board,
    required this.jointCount,
    required this.pins,
    required this.driverType,
    this.isActive = false,
    required this.joints,
  });
}
