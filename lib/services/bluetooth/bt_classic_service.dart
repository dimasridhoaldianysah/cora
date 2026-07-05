import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import '../../core/utils/permission_helper.dart';

enum BtConnectionState { disconnected, connecting, connected, error }

class BtClassicService {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  
  // Connection state management is handled by the calling Provider layer.
  // This service exclusively encapsulates core Bluetooth logic.

  Future<List<BluetoothDevice>> scan(BuildContext context) async {
    final hasPermission = await PermissionHelper.requestBluetoothPermission(context);
    if (!hasPermission) {
      throw Exception('Izin Bluetooth tidak diberikan.');
    }
    
    // Return bonded devices immediately for Classic Bluetooth.
    // Device discovery for unpaired devices can be added via `startDiscovery()` if needed.
    return await _bluetooth.getBondedDevices();
  }

  Future<void> connect(String address, {required Function onDisconnected}) async {
    if (_connection != null && _connection!.isConnected) {
      await disconnect();
    }
    
    _connection = await BluetoothConnection.toAddress(address);
    
    _connection!.input!.listen(
      (data) {
        // Handle incoming telemetry from robot if necessary
      },
      onDone: () {
        onDisconnected();
      },
      onError: (error) {
        onDisconnected();
      },
      cancelOnError: true,
    );
  }

  Future<void> disconnect() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
    }
  }

  void send(String data) {
    if (_connection != null && _connection!.isConnected) {
      // Ensure command is properly terminated for the microcontroller's serial buffer
      final formattedData = data.endsWith('\n') ? data : '$data\n';
      final bytes = utf8.encode(formattedData);
      _connection!.output.add(bytes);
    }
  }
  
  // Optional: Expose the raw input stream if we want to read from device
  Stream<List<int>>? get receiveStream => _connection?.input;
  

}
