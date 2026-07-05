import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'bt_provider.dart';
import 'control_provider.dart';

// Waktu fisik yang diestimasi per derajat gerakan servo.
// Firmware stepDelay = 15ms/° (di kode C++), tapi servo fisik
// dengan beban robot arm dan BT latency bisa 2× lebih lambat.
// Kalau masih gagal di loop mode, naikkan nilai ini (coba 35 atau 40).
const int _kMsPerDegree = 32;

// Buffer ekstra setelah estimasi gerakan selesai.
const int _kBufferMs = 700;

class PoseState {
  final List<List<int>> poseList;
  final bool isPlaying;
  final bool isLooping;

  const PoseState({
    this.poseList = const [],
    this.isPlaying = false,
    this.isLooping = false,
  });

  PoseState copyWith({
    List<List<int>>? poseList,
    bool? isPlaying,
    bool? isLooping,
  }) {
    return PoseState(
      poseList: poseList ?? this.poseList,
      isPlaying: isPlaying ?? this.isPlaying,
      isLooping: isLooping ?? this.isLooping,
    );
  }
}

class PoseNotifier extends StateNotifier<PoseState> {
  PoseNotifier() : super(const PoseState());

  void savePose(List<int> currentJointValues) {
    if (state.isPlaying) return; // Prevent saving during playback
    final newPoseList = List<List<int>>.from(state.poseList);
    newPoseList.add(List<int>.from(currentJointValues));
    state = state.copyWith(poseList: newPoseList);
  }

  void deletePose(int index) {
    if (state.isPlaying) return;
    if (index < 0 || index >= state.poseList.length) return;
    final newPoseList = List<List<int>>.from(state.poseList);
    newPoseList.removeAt(index);
    state = state.copyWith(poseList: newPoseList);
  }

  void clearAll() {
    if (state.isPlaying) return;
    state = state.copyWith(poseList: []);
  }

  void toggleLoop(bool loop) {
    state = state.copyWith(isLooping: loop);
  }

  /// Hitung estimasi waktu gerak servo berdasarkan delta sudut terbesar.
  ///
  /// Rumus: maxDelta × _kMsPerDegree + _kBufferMs
  ///
  /// Contoh (dengan _kMsPerDegree=30):
  ///   gerak  10° → 10  × 30ms =  300ms + 1500ms buffer = 1800ms
  ///   gerak  60° → 60  × 30ms = 1800ms + 1500ms buffer = 3300ms
  ///   gerak 110° → 110 × 30ms = 3300ms + 1500ms buffer = 4800ms
  ///   gerak 180° → 180 × 30ms = 5400ms + 1500ms buffer = 6900ms
  int _estimateDelayMs(List<int> prevValues, List<int> nextPose) {
    int maxDelta = 0;
    final len = prevValues.length < nextPose.length
        ? prevValues.length
        : nextPose.length;
    for (int j = 0; j < len; j++) {
      final delta = (nextPose[j] - prevValues[j]).abs();
      if (delta > maxDelta) maxDelta = delta;
    }
    return (maxDelta * _kMsPerDegree) + _kBufferMs;
  }

  Future<void> startPlayback(
    BtNotifier btNotifier,
    ControlNotifier controlNotifier,
  ) async {
    if (state.poseList.isEmpty || state.isPlaying) return;

    state = state.copyWith(isPlaying: true);
    controlNotifier.lockSliders();

    try {
      do {
        for (int i = 0; i < state.poseList.length; i++) {
          if (!state.isPlaying) return; // guard

          final pose = state.poseList[i];

          // Ambil posisi SEBELUM update untuk hitung delta sudut
          final prevValues = List<int>.from(controlNotifier.state.jointValues);

          // Update slider UI ke posisi pose berikutnya
          controlNotifier.setJoints(pose);

          // Kirim perintah ke robot via Bluetooth
          for (int j = 0; j < pose.length; j++) {
            btNotifier.send('J$j:${pose[j]}\n');
          }

          // Delay dinamis berdasarkan jarak gerak terbesar antar joint:
          //   waktu gerak estimasi + 1 detik buffer
          // Jauh lebih efisien dari flat 4500ms sebelumnya.
          final delayMs = _estimateDelayMs(prevValues, pose);
          await Future.delayed(Duration(milliseconds: delayMs));

          if (!state.isPlaying) return; // check setelah delay
        }
      } while (state.isLooping && state.isPlaying);
    } finally {
      if (state.isPlaying) {
        // Selesai natural (bukan di-stop manual)
        state = state.copyWith(isPlaying: false);
        controlNotifier.unlockSliders();
      }
    }
  }

  void stopPlayback(ControlNotifier controlNotifier) {
    state = state.copyWith(isPlaying: false);
    controlNotifier.unlockSliders();
  }

  Future<void> moveToDefaultPose(
    List<dynamic> jointConfigs, // using dynamic to avoid importing joint_config here if not needed, or better pass a List of target angles
    BtNotifier btNotifier,
    ControlNotifier controlNotifier,
  ) async {
    if (state.isPlaying) return;

    state = state.copyWith(isPlaying: true);
    controlNotifier.lockSliders();

    try {
      for (int i = 0; i < jointConfigs.length; i++) {
        if (!state.isPlaying) return;

        final config = jointConfigs[i];
        final int targetAngle = config.defaultAngle != -1 
            ? config.defaultAngle 
            : ((config.minAngle + config.maxAngle) / 2).round();

        // Update single joint in state bypassing lock
        final newValues = List<int>.from(controlNotifier.state.jointValues);
        if (i < newValues.length) {
          newValues[i] = targetAngle;
          controlNotifier.setJoints(newValues);
        }

        // Send to Bluetooth
        btNotifier.send('J$i:$targetAngle\n');

        // Delay 1 second (1000ms) for each servo movement
        await Future.delayed(const Duration(milliseconds: 1000));
      }
    } finally {
      if (state.isPlaying) {
        state = state.copyWith(isPlaying: false);
        controlNotifier.unlockSliders();
      }
    }
  }
}

final poseProvider = StateNotifierProvider<PoseNotifier, PoseState>((ref) {
  return PoseNotifier();
});
