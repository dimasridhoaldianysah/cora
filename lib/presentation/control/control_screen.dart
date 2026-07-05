import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/bt_provider.dart';
import '../../../providers/control_provider.dart';
import '../../../providers/pose_provider.dart';
import '../../../providers/profile_provider.dart';
import 'widgets/joint_slider.dart';

class ControlScreen extends ConsumerStatefulWidget {
  const ControlScreen({super.key});

  @override
  ConsumerState<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends ConsumerState<ControlScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeProfile = ref.read(profileProvider).activeProfile;
      if (activeProfile != null) {
        ref
            .read(controlProvider.notifier)
            .initJoints(activeProfile.jointCount, activeProfile.joints);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 1. Unconditional ref.listen for Failsafe
    ref.listen<BtState>(btProvider, (previous, next) {
      if (previous?.isConnected == true && next.isConnected == false) {
        if (ref.read(poseProvider).isPlaying) {
          ref
              .read(poseProvider.notifier)
              .stopPlayback(ref.read(controlProvider.notifier));

          if (context.mounted) {
            showDialog(
              context: context,
              builder: (dialogContext) => AlertDialog(
                title: const Text('Koneksi Terputus'),
                content: const Text(
                  'Playback dihentikan. Hubungkan ulang '
                  'robot sebelum melanjutkan.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialogContext),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          }
        }
      }
    });

    final activeProfile = ref.watch(profileProvider).activeProfile;
    final btState = ref.watch(btProvider);
    final controlState = ref.watch(controlProvider);
    final poseState = ref.watch(poseProvider);
    final isConnected = btState.isConnected;

    if (activeProfile == null) {
      return Container(
        width: double.infinity,
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amber),
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.all(12),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Belum ada profil aktif. Silakan pilih atau buat profil di Pengaturan.',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (!isConnected)
          Container(
            width: double.infinity,
            color: Theme.of(context).colorScheme.surface,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.amber),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(12),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.amber),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hubungkan robot untuk mulai kontrol',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: Row(
            children: [
              // Panel Kiri (60%)
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: activeProfile.jointCount,
                          itemBuilder: (context, index) {
                            final jointConfig =
                                index < activeProfile.joints.length
                                ? activeProfile.joints[index]
                                : null;
                            final minAngle = jointConfig?.minAngle ?? 0;
                            final maxAngle = jointConfig?.maxAngle ?? 180;
                            final value =
                                (index < controlState.jointValues.length)
                                ? controlState.jointValues[index]
                                : minAngle;

                            return JointSlider(
                              jointIndex: index,
                              minAngle: minAngle,
                              maxAngle: maxAngle,
                              value: value,
                              isLocked: controlState.isLocked,
                              isConnected: isConnected,
                              onChanged: (controlState.isLocked || !isConnected)
                                  ? null
                                  : (val) {
                                      ref
                                          .read(controlProvider.notifier)
                                          .updateJoint(
                                            index,
                                            val.round(),
                                            activeProfile.joints,
                                          );
                                    },
                              onChangeEnd:
                                  (controlState.isLocked || !isConnected)
                                  ? null
                                  : (val) {
                                      ref
                                          .read(btProvider.notifier)
                                          .send('J$index:${val.round()}\n');
                                    },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const VerticalDivider(width: 1),
              // Panel Kanan (40%)
              Expanded(
                flex: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'TEACH & RECORD',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text('Pose tersimpan: ${poseState.poseList.length}'),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            itemCount: poseState.poseList.length,
                            itemBuilder: (context, index) {
                              final pose = poseState.poseList[index];
                              return ListTile(
                                dense: true,
                                title: Text('[$index] ${pose.join(', ')}'),
                                trailing: IconButton(
                                  icon: Icon(
                                    Icons.delete,
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                  onPressed:
                                      (!isConnected || poseState.isPlaying)
                                      ? null
                                      : () {
                                          ref
                                              .read(poseProvider.notifier)
                                              .deletePose(index);
                                        },
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        alignment: WrapAlignment.center,
                        children: [
                          FilledButton.icon(
                                onPressed:
                                    (isConnected &&
                                        !poseState.isPlaying &&
                                        poseState.poseList.isNotEmpty)
                                    ? () {
                                        ref
                                            .read(poseProvider.notifier)
                                            .startPlayback(
                                              ref.read(btProvider.notifier),
                                              ref.read(
                                                controlProvider.notifier,
                                              ),
                                            );
                                      }
                                    : null,
                                icon: const Icon(Icons.play_arrow),
                            label: const Text('Play'),
                          ),
                          FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.onError,
                                ),
                                onPressed: (isConnected && poseState.isPlaying)
                                    ? () {
                                        ref
                                            .read(poseProvider.notifier)
                                            .stopPlayback(
                                              ref.read(
                                                controlProvider.notifier,
                                              ),
                                            );
                                      }
                                    : null,
                                icon: const Icon(Icons.stop),
                            label: const Text('Stop'),
                          ),
                          FilledButton.icon(
                                onPressed:
                                    (!isConnected ||
                                        controlState.isLocked ||
                                        poseState.isPlaying)
                                    ? null
                                    : () {
                                        ref
                                            .read(poseProvider.notifier)
                                            .savePose(controlState.jointValues);
                                      },
                                icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Loop'),
                              Switch(
                                value: poseState.isLooping,
                                onChanged: (!isConnected || poseState.isPlaying)
                                    ? null
                                    : (val) {
                                        ref
                                            .read(poseProvider.notifier)
                                            .toggleLoop(val);
                                      },
                              ),
                            ],
                          ),
                          OutlinedButton.icon(
                            onPressed: (!isConnected || poseState.isPlaying)
                                    ? null
                                    : () {
                                        ref
                                            .read(poseProvider.notifier)
                                            .moveToDefaultPose(
                                              activeProfile.joints,
                                              ref.read(btProvider.notifier),
                                              ref.read(
                                                controlProvider.notifier,
                                              ),
                                            );
                                      },
                                icon: const Icon(Icons.sensor_occupied),
                            label: const Text('Default'),
                          ),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.error,
                              side: BorderSide(color: Theme.of(context).colorScheme.error.withOpacity(0.5)),
                            ),
                            onPressed:
                                    (!isConnected ||
                                        poseState.isPlaying ||
                                        poseState.poseList.isEmpty)
                                    ? null
                                    : () {
                                        showDialog(
                                          context: context,
                                          builder: (dialogContext) =>
                                              AlertDialog(
                                                title: const Text('Reset'),
                                                content: const Text(
                                                  'Hapus semua pose tersimpan?',
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () =>
                                                        Navigator.pop(
                                                          dialogContext,
                                                        ),
                                                    child: const Text('Batal'),
                                                  ),
                                                  FilledButton(
                                                    style: FilledButton.styleFrom(
                                                      backgroundColor: Theme.of(context).colorScheme.error,
                                                      foregroundColor: Theme.of(context).colorScheme.onError,
                                                    ),
                                                    onPressed: () {
                                                      Navigator.pop(
                                                        dialogContext,
                                                      ); // Tutup dialog dulu
                                                      ref
                                                          .read(
                                                            poseProvider
                                                                .notifier,
                                                          )
                                                          .clearAll();
                                                    },
                                                    child: const Text('Hapus'),
                                                  ),
                                                ],
                                              ),
                                        );
                                      },
                            icon: const Icon(Icons.delete_sweep),
                            label: const Text('Reset'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
