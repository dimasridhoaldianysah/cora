import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/joint_config.dart';
import '../../../data/models/robot_profile.dart';
import '../../../providers/profile_provider.dart';
import '../../../core/theme/app_theme.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  final String? profileId;

  const ProfileFormScreen({super.key, this.profileId});

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  String _selectedBoard = 'uno';
  String _selectedDriver = 'pca9685';
  int _jointCount = 1;

  List<JointConfig> _joints = [];

  bool _isFormValid = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();

    if (widget.profileId != null) {
      // Edit mode
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final profileState = ref.read(profileProvider);
        final profile = profileState.profiles.firstWhere(
          (p) => p.id == widget.profileId,
          orElse: () => RobotProfile(
            id: '',
            name: '',
            board: 'uno',
            jointCount: 1,
            pins: [],
            driverType: 'pca9685',
            joints: [],
          ),
        );

        if (profile.id.isNotEmpty) {
          setState(() {
            _nameController.text = profile.name;
            _selectedBoard = profile.board;
            _selectedDriver = profile.driverType;
            _jointCount = profile.jointCount;
            // Create deep copy of joints to avoid mutating the Hive object directly before save
            _joints = profile.joints
                .map(
                  (j) => JointConfig(
                    index: j.index,
                    pinNumber: j.pinNumber,
                    minAngle: j.minAngle,
                    maxAngle: j.maxAngle,
                    servoMin: j.servoMin,
                    servoMax: j.servoMax,
                    defaultAngle: j.defaultAngle,
                  ),
                )
                .toList();
          });
        } else {
          _initializeDefaultJoints();
        }
        _validateJoints();
      });
    } else {
      // Create mode
      _initializeDefaultJoints();
    }
  }

  void _initializeDefaultJoints() {
    _joints = List.generate(
      _jointCount,
      (index) => JointConfig(
        index: index,
        pinNumber: index,
        minAngle: 0,
        maxAngle: 180,
        servoMin: 150,
        servoMax: 600,
        defaultAngle: -1,
      ),
    );
  }

  void _updateJointCount(int newCount) {
    setState(() {
      if (newCount > _jointCount) {
        // Add new joints
        for (int i = _jointCount; i < newCount; i++) {
          _joints.add(
            JointConfig(
              index: i,
              pinNumber: i,
              minAngle: 0,
              maxAngle: 180,
              servoMin: 150,
              servoMax: 600,
              defaultAngle: -1,
            ),
          );
        }
      } else if (newCount < _jointCount) {
        // Remove joints from the end
        _joints.removeRange(newCount, _jointCount);
      }
      _jointCount = newCount;
      _validateJoints();
    });
  }

  void _validateJoints() {
    bool isValid = true;
    for (var joint in _joints) {
      if (joint.minAngle < 0 ||
          joint.maxAngle > 180 ||
          joint.minAngle >= joint.maxAngle) {
        isValid = false;
        break;
      }
      if (joint.defaultAngle != -1) {
        if (joint.defaultAngle < joint.minAngle || joint.defaultAngle > joint.maxAngle) {
          isValid = false;
          break;
        }
      }
      if (_selectedDriver == 'pca9685') {
        if (joint.servoMin < 0 ||
            joint.servoMax > 4095 ||
            joint.servoMin >= joint.servoMax) {
          isValid = false;
          break;
        }
      }
    }

    // Also validate the overall form if initialized
    if (_nameController.text.trim().isEmpty) {
      isValid = false;
    }

    if (_isFormValid != isValid) {
      setState(() {
        _isFormValid = isValid;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate() || !_isFormValid) return;

    final profile = RobotProfile(
      id:
          widget.profileId ??
          '', // Empty ID will be generated in provider if new
      name: _nameController.text.trim(),
      board: _selectedBoard,
      jointCount: _jointCount,
      pins: _joints.map((j) => j.pinNumber).toList(),
      driverType: _selectedDriver,
      joints: _joints,
    );

    if (widget.profileId == null) {
      ref.read(profileProvider.notifier).addProfile(profile);
    } else {
      // Retain active status when editing
      final existing = ref
          .read(profileProvider)
          .profiles
          .firstWhere((p) => p.id == widget.profileId);
      profile.isActive = existing.isActive;
      ref.read(profileProvider.notifier).updateProfile(profile);
    }

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Form(
        key: _formKey,
        onChanged: _validateJoints,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Panel: Basic Info
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Informasi Dasar',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Robot',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Nama wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedBoard,
                      decoration: const InputDecoration(
                        labelText: 'Board Target',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'uno',
                          child: Text('Arduino Uno'),
                        ),
                        DropdownMenuItem(
                          value: 'nano',
                          child: Text('Arduino Nano'),
                        ),
                        DropdownMenuItem(value: 'esp32', child: Text('ESP32')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedBoard = val);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Jenis Driver',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('PCA9685'),
                            value: 'pca9685',
                            groupValue: _selectedDriver,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDriver = val;
                                  _validateJoints();
                                });
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: RadioListTile<String>(
                            title: const Text('Direct MCU'),
                            value: 'direct',
                            groupValue: _selectedDriver,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedDriver = val;
                                  _validateJoints();
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text(
                          'Jumlah Joint: $_jointCount',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: _jointCount > 1
                              ? () => _updateJointCount(_jointCount - 1)
                              : null,
                        ),
                        Slider(
                          value: _jointCount.toDouble(),
                          min: 1,
                          max: 6,
                          divisions: 5,
                          onChanged: (val) => _updateJointCount(val.toInt()),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: _jointCount < 6
                              ? () => _updateJointCount(_jointCount + 1)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isFormValid ? _saveProfile : null,
                        child: const Text('Simpan Profil'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const VerticalDivider(width: 1),

            // Right Panel: Joint Config
            Expanded(
              flex: 1,
              child: ListView(
                padding: const EdgeInsets.all(24.0),
                children: [
                  Text(
                    'Konfigurasi Pin & Range Sudut',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Validasi: 0 <= Min < Max <= 180',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).extension<CustomColors>()?.warning,
                        ),
                  ),
                  if (_selectedDriver == 'pca9685') ...[
                    const SizedBox(height: 4),
                    Text(
                      'Referensi nilai pulse PCA9685 PWM 50Hz —\n'
                      '- SG90: 102/492, \n'
                      '- MG90S: 123/492, \n'
                      '- MG996R: 143/471, \n'
                      '- DS3225: 102/512, \n'
                      '- HS-645MG: 184/430, \n'
                      '- MG92B: 143/471. \n\n'
                      'Nilai ini adalah titik awal kalibrasi, sesuaikan jika servo bergetar atau tidak presisi.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  ..._joints.asMap().entries.map((entry) {
                    final index = entry.key;
                    final joint = entry.value;
                    bool isInvalidRange =
                        joint.minAngle < 0 ||
                        joint.maxAngle > 180 ||
                        joint.minAngle >= joint.maxAngle;
                    
                    if (joint.defaultAngle != -1 && (joint.defaultAngle < joint.minAngle || joint.defaultAngle > joint.maxAngle)) {
                      isInvalidRange = true;
                    }

                    if (_selectedDriver == 'pca9685') {
                      if (joint.servoMin < 0 ||
                          joint.servoMax > 4095 ||
                          joint.servoMin >= joint.servoMax) {
                        isInvalidRange = true;
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isInvalidRange
                              ? Colors.redAccent
                              : Colors.transparent,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 80,
                                  child: Text(
                                    'Joint ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: joint.pinNumber.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Pin/Ch',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      joint.pinNumber = int.tryParse(val) ?? 0;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: joint.minAngle.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Min °',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      joint.minAngle = int.tryParse(val) ?? 0;
                                      _validateJoints();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: joint.maxAngle.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Max °',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      joint.maxAngle = int.tryParse(val) ?? 180;
                                      _validateJoints();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    initialValue: joint.defaultAngle == -1 ? '' : joint.defaultAngle.toString(),
                                    decoration: const InputDecoration(
                                      labelText: 'Def °',
                                      hintText: 'Tengah',
                                      isDense: true,
                                    ),
                                    keyboardType: TextInputType.number,
                                    onChanged: (val) {
                                      joint.defaultAngle = val.isEmpty ? -1 : (int.tryParse(val) ?? -1);
                                      _validateJoints();
                                    },
                                  ),
                                ),
                              ],
                            ),
                            if (_selectedDriver == 'pca9685') ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  const SizedBox(width: 80),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: joint.servoMin.toString(),
                                      decoration: const InputDecoration(
                                        labelText: 'Pulse Min',
                                        hintText: 'mis. 150',
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) {
                                        joint.servoMin = int.tryParse(val) ?? 150;
                                        _validateJoints();
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      initialValue: joint.servoMax.toString(),
                                      decoration: const InputDecoration(
                                        labelText: 'Pulse Max',
                                        hintText: 'mis. 600',
                                        isDense: true,
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (val) {
                                        joint.servoMax = int.tryParse(val) ?? 600;
                                        _validateJoints();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
