import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../../../providers/bt_provider.dart';
import '../../../providers/profile_provider.dart';

class BtScannerSheet extends ConsumerStatefulWidget {
  const BtScannerSheet({super.key});

  @override
  ConsumerState<BtScannerSheet> createState() => _BtScannerSheetState();
}

class _BtScannerSheetState extends ConsumerState<BtScannerSheet> {
  String _scanMode = 'classic'; // 'classic' or 'ble'
  bool _isScanning = false;
  
  List<BluetoothDevice> _classicDevices = [];
  final List<DiscoveredDevice> _bleDevices = [];
  
  @override
  void initState() {
    super.initState();
    // Delay slightly to let the sheet render, then determine initial state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeProfile = ref.read(profileProvider).activeProfile;
      if (activeProfile?.board == 'esp32') {
        _scanMode = 'ble';
      } else {
        _scanMode = 'classic';
      }
      setState(() {});
      _startScan();
    });
  }

  void _startScan() async {
    setState(() {
      _isScanning = true;
      _classicDevices.clear();
      _bleDevices.clear();
    });

    try {
      final notifier = ref.read(btProvider.notifier);
      if (_scanMode == 'classic') {
        final devices = await notifier.classicService.scan(context);
        if (mounted) {
          setState(() {
            _classicDevices = devices;
            _isScanning = false;
          });
        }
      } else if (_scanMode == 'ble') {
        notifier.bleService.scan(context).listen((device) {
          if (mounted) {
            setState(() {
              final idx = _bleDevices.indexWhere((d) => d.id == device.id);
              if (idx >= 0) {
                _bleDevices[idx] = device;
              } else {
                _bleDevices.add(device);
              }
            });
          }
        }, onDone: () {
          if (mounted) {
            setState(() {
              _isScanning = false;
            });
          }
        }, onError: (e) {
          if (mounted) {
            setState(() {
              _isScanning = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Terjadi kesalahan. Pastikan Bluetooth aktif dan memiliki izin.')));
          }
        });
        
        // Auto stop BLE scan after 10 seconds
        Future.delayed(const Duration(seconds: 10), () {
          if (mounted && _isScanning && _scanMode == 'ble') {
            setState(() {
              _isScanning = false;
            });
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal memindai perangkat. Periksa izin Bluetooth Anda.')));
      }
    }
  }
  
  void _connectClassic(BluetoothDevice device) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      // Tampilkan indikator loading atau tutup sheet dan biarkan background connect
      navigator.pop();
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Menghubungkan ke ${device.name ?? device.address}...')));
      
      await ref.read(btProvider.notifier).connectClassic(device.address, device.name ?? 'Unknown');
      
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Terhubung ke ${device.name}')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Gagal terhubung. Pastikan robot menyala dan belum terhubung ke HP lain.'), backgroundColor: Colors.red));
    }
  }

  void _connectBle(DiscoveredDevice device) async {
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    try {
      navigator.pop();
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Menghubungkan ke ${device.name}...')));
      
      await ref.read(btProvider.notifier).connectBle(device.id, device.name);
      
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Terhubung ke ${device.name}')));
    } catch (e) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Gagal terhubung. Pastikan robot menyala dan berada dalam jangkauan.'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeProfile = ref.watch(profileProvider).activeProfile;
    final isEsp32 = activeProfile?.board == 'esp32';

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Pindai Perangkat', style: Theme.of(context).textTheme.titleLarge),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: _isScanning ? null : _startScan,
              ),
            ],
          ),
          
          if (ref.watch(btProvider).isConnected) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.bluetooth_connected),
                title: Text('Terhubung: ${ref.watch(btProvider).deviceName}'),
                trailing: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: () async {
                    await ref.read(btProvider.notifier).disconnect();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Koneksi terputus.')),
                      );
                    }
                  },
                  child: const Text('Putuskan'),
                ),
              ),
            ),
            const Divider(height: 32),
          ] else ...[
            const SizedBox(height: 16),
          ],

          if (isEsp32)
            Center(
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'ble', label: Text('BLE (Direkomendasikan)')),
                  ButtonSegment(value: 'classic', label: Text('Classic')),
                ],
                selected: {_scanMode},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _scanMode = newSelection.first;
                  });
                  _startScan();
                },
              ),
            ),
          if (isEsp32) const SizedBox(height: 16),
          if (_isScanning) const LinearProgressIndicator(),
          const SizedBox(height: 8),
          Expanded(
            child: _scanMode == 'classic' ? _buildClassicList() : _buildBleList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildClassicList() {
    if (_classicDevices.isEmpty && !_isScanning) {
      return const Center(child: Text('Tidak ada perangkat Classic tersimpan ditemukan.'));
    }
    return ListView.builder(
      itemCount: _classicDevices.length,
      itemBuilder: (context, index) {
        final device = _classicDevices[index];
        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(device.name ?? 'Unknown Device'),
          subtitle: Text(device.address),
          onTap: () => _connectClassic(device),
        );
      },
    );
  }

  Widget _buildBleList() {
    if (_bleDevices.isEmpty && !_isScanning) {
      return const Center(child: Text('Tidak ada perangkat BLE ditemukan. Pastikan robot menyala.'));
    }
    return ListView.builder(
      itemCount: _bleDevices.length,
      itemBuilder: (context, index) {
        final device = _bleDevices[index];
        return ListTile(
          leading: const Icon(Icons.bluetooth_searching),
          title: Text(device.name.isNotEmpty ? device.name : 'Unknown BLE Device'),
          subtitle: Text(device.id),
          trailing: Text('${device.rssi} dBm'),
          onTap: () => _connectBle(device),
        );
      },
    );
  }
}
