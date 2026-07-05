import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionHelper {
  static Future<void> _showSettingsDialog(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Izin Bluetooth Ditolak'),
        content: const Text('CORA membutuhkan akses Bluetooth untuk mengontrol robot. Silakan berikan izin melalui Pengaturan Sistem.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }

  static Future<bool> requestBluetoothPermission(BuildContext context) async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 31) {
      final statuses = await [
        Permission.bluetoothScan,
        Permission.bluetoothConnect,
      ].request();
      
      final scanStatus = statuses[Permission.bluetoothScan];
      final connectStatus = statuses[Permission.bluetoothConnect];
      
      if (scanStatus?.isPermanentlyDenied == true || connectStatus?.isPermanentlyDenied == true) {
        if (context.mounted) {
          await _showSettingsDialog(context);
        }
      }
      
      return scanStatus?.isGranted == true && connectStatus?.isGranted == true;
    } else {
      final status = await Permission.locationWhenInUse.request();
      if (status.isPermanentlyDenied) {
        if (context.mounted) {
          await _showSettingsDialog(context);
        }
      }
      return status.isGranted;
    }
  }

  static Future<bool> requestStoragePermission() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    if (androidInfo.version.sdkInt >= 33) {
      return true; // No permission needed for Android 13+
    } else {
      final status = await Permission.storage.request();
      return status.isGranted;
    }
  }
}
