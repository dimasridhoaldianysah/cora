class BtConstants {
  // Common SPP UUID
  static const String sppUuid = "00001101-0000-1000-8000-00805F9B34FB";
  static const int baudRate = 9600;

  // Nordic UART Service (NUS) — standar de facto BLE serial
  static const String bleServiceUuid = '6E400001-B5A3-F393-E0A9-E50E24DCCA9E';
  
  // ESP32 -> phone
  static const String bleTxCharUuid = '6E400003-B5A3-F393-E0A9-E50E24DCCA9E';
  
  // phone -> ESP32 (write)
  static const String bleRxCharUuid = '6E400002-B5A3-F393-E0A9-E50E24DCCA9E';
}
