import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/joint_config.dart';

class ControlState {
  final List<int> jointValues;
  final bool isLocked;

  const ControlState({
    this.jointValues = const [],
    this.isLocked = false,
  });

  ControlState copyWith({
    List<int>? jointValues,
    bool? isLocked,
  }) {
    return ControlState(
      jointValues: jointValues ?? this.jointValues,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

class ControlNotifier extends StateNotifier<ControlState> {
  ControlNotifier() : super(const ControlState());

  void initJoints(int count, List<JointConfig> configs) {
    if (state.jointValues.length == count) return;
    
    final initialValues = List<int>.generate(count, (index) {
      if (index < configs.length) {
        final config = configs[index];
        if (config.defaultAngle != -1) {
          return config.defaultAngle;
        }
        return ((config.minAngle + config.maxAngle) / 2).round();
      }
      return 90; // Fallback
    });

    state = state.copyWith(jointValues: initialValues);
  }

  void updateJoint(int idx, int value, List<JointConfig> configs) {
    if (state.isLocked) return;
    
    if (idx < 0 || idx >= state.jointValues.length) return;
    
    int minAngle = 0;
    int maxAngle = 180;
    
    if (idx < configs.length) {
      minAngle = configs[idx].minAngle;
      maxAngle = configs[idx].maxAngle;
    }

    final clampedValue = value.clamp(minAngle, maxAngle);

    final newValues = List<int>.from(state.jointValues);
    newValues[idx] = clampedValue;
    
    state = state.copyWith(jointValues: newValues);
  }

  void setJoints(List<int> values) {
    state = state.copyWith(jointValues: values);
  }

  void lockSliders() {
    state = state.copyWith(isLocked: true);
  }

  void unlockSliders() {
    state = state.copyWith(isLocked: false);
  }
}

final controlProvider = StateNotifierProvider<ControlNotifier, ControlState>((ref) {
  return ControlNotifier();
});
