import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';
import '../../core/constants/bt_constants.dart';
import '../../core/utils/permission_helper.dart';

class BleService {
  final FlutterReactiveBle _ble = FlutterReactiveBle();
  StreamSubscription<ConnectionStateUpdate>? _connectionSub;
  String? _connectedDeviceId;

  // Stream for scanning
  Stream<DiscoveredDevice> scan(BuildContext context) async* {
    final hasPermission = await PermissionHelper.requestBluetoothPermission(context);
    if (!hasPermission) {
      throw Exception('Izin Bluetooth tidak diberikan.');
    }

    final serviceUuid = Uuid.parse(BtConstants.bleServiceUuid);
    
    // Note: Some Android OEM implementations have bugs with hardware-level BLE scan filtering.
    // To ensure reliable discovery across all devices, we bypass the native `withServices` filter
    // and manually filter the results in Dart logic based on the advertised serviceUuids.    
    yield* _ble.scanForDevices(
      withServices: [], // Intentionally empty to bypass OEM bugs
      scanMode: ScanMode.lowLatency,
    ).where((device) {
      // Manual fallback filtering in Dart
      return device.serviceUuids.contains(serviceUuid);
    });
  }

  Future<void> connect(String deviceId, {required Function(bool) onConnectionChanged}) async {
    await disconnect();
    
    _connectionSub = _ble.connectToDevice(
      id: deviceId,
      connectionTimeout: const Duration(seconds: 5),
    ).listen((update) {
      if (update.connectionState == DeviceConnectionState.connected) {
        _connectedDeviceId = deviceId;
        onConnectionChanged(true);
      } else if (update.connectionState == DeviceConnectionState.disconnected) {
        _connectedDeviceId = null;
        onConnectionChanged(false);
      }
    }, onError: (error) {
      _connectedDeviceId = null;
      onConnectionChanged(false);
    });
  }

  Future<void> disconnect() async {
    if (_connectionSub != null) {
      await _connectionSub!.cancel();
      _connectionSub = null;
    }
    _connectedDeviceId = null;
  }

  void send(String data) {
    if (_connectedDeviceId != null) {
      // Append newline terminator required by the firmware's serial parser
      final formattedData = data.endsWith('\n') ? data : '$data\n';
      final bytes = utf8.encode(formattedData);
      
      final characteristic = QualifiedCharacteristic(
        serviceId: Uuid.parse(BtConstants.bleServiceUuid),
        characteristicId: Uuid.parse(BtConstants.bleRxCharUuid),
        deviceId: _connectedDeviceId!,
      );
      
      _ble.writeCharacteristicWithoutResponse(characteristic, value: bytes);
    }
  }
}
