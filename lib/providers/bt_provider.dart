import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/bluetooth/bt_classic_service.dart';
import '../services/bluetooth/ble_service.dart';

class BtState {
  final bool isConnected;
  final String? deviceName;
  final String? connectionType; // 'classic' or 'ble'

  const BtState({
    this.isConnected = false,
    this.deviceName,
    this.connectionType,
  });

  BtState copyWith({
    bool? isConnected,
    String? deviceName,
    String? connectionType,
  }) {
    return BtState(
      isConnected: isConnected ?? this.isConnected,
      deviceName: deviceName ?? this.deviceName,
      connectionType: connectionType ?? this.connectionType,
    );
  }
}

class BtNotifier extends StateNotifier<BtState> {
  final BtClassicService _classicService = BtClassicService();
  final BleService _bleService = BleService();

  final StreamController<void> _disconnectController = StreamController<void>.broadcast();
  Stream<void> get onDisconnected => _disconnectController.stream;

  BtNotifier() : super(const BtState());

  @override
  void dispose() {
    _disconnectController.close();
    _classicService.disconnect();
    _bleService.disconnect();
    super.dispose();
  }

  // To be called when connection drops
  void _triggerDisconnect() {
    state = const BtState(isConnected: false);
    _disconnectController.add(null);
  }

  Future<void> connectClassic(String address, String name) async {
    try {
      await _classicService.connect(address, onDisconnected: () {
        if (state.isConnected && state.connectionType == 'classic') {
          _triggerDisconnect();
        }
      });
      state = BtState(
        isConnected: true,
        deviceName: name,
        connectionType: 'classic',
      );
    } catch (e) {
      _triggerDisconnect();
      rethrow;
    }
  }

  Future<void> connectBle(String deviceId, String name) async {
    final completer = Completer<void>();
    bool isFirstEvent = true;

    await _bleService.connect(deviceId, onConnectionChanged: (isConnected) {
      if (isConnected) {
        state = BtState(
          isConnected: true,
          deviceName: name,
          connectionType: 'ble',
        );
        if (isFirstEvent) {
          isFirstEvent = false;
          completer.complete();
        }
      } else {
        if (isFirstEvent) {
          isFirstEvent = false;
          completer.completeError('Failed to connect to BLE device.');
        } else {
          // Disconnected mid-session
          if (state.isConnected && state.connectionType == 'ble') {
            _triggerDisconnect();
          }
        }
      }
    });

    return completer.future;
  }

  Future<void> disconnect() async {
    if (state.connectionType == 'classic') {
      await _classicService.disconnect();
    } else if (state.connectionType == 'ble') {
      await _bleService.disconnect();
    }
    _triggerDisconnect();
  }

  void send(String data) {
    if (state.connectionType == 'classic') {
      _classicService.send(data);
    } else if (state.connectionType == 'ble') {
      _bleService.send(data);
    }
  }
  
  BtClassicService get classicService => _classicService;
  BleService get bleService => _bleService;
}

final btProvider = StateNotifierProvider<BtNotifier, BtState>((ref) {
  return BtNotifier();
});
