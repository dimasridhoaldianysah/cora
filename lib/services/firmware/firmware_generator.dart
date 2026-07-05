import '../../data/models/robot_profile.dart';

class FirmwareGenerator {
  static String generate(RobotProfile profile) {
    final isEsp32 = profile.board == 'esp32';
    final isPca9685 = profile.driverType == 'pca9685';
    final jointCount = profile.jointCount;
    
    final pinArray = profile.joints.map((j) => j.pinNumber.toString()).join(', ');
    final minAngleArray = profile.joints.map((j) => j.minAngle.toString()).join(', ');
    final maxAngleArray = profile.joints.map((j) => j.maxAngle.toString()).join(', ');
    
    final buffer = StringBuffer();
    
    // 1. Headers & Includes
    buffer.writeln('// Auto-generated firmware for CORA Robotic Arm');
    buffer.writeln('// Robot: ${profile.name}');
    buffer.writeln('// Board: ${profile.board.toUpperCase()}');
    buffer.writeln('// Driver: ${profile.driverType.toUpperCase()}');
    buffer.writeln();
    
    if (isEsp32) {
      buffer.writeln('#include "BluetoothSerial.h"');
      buffer.writeln('BluetoothSerial SerialBT;');
    }
    
    if (isPca9685) {
      buffer.writeln('#include <Wire.h>');
      buffer.writeln('#include <Adafruit_PWMServoDriver.h>');
      buffer.writeln('Adafruit_PWMServoDriver pwm = Adafruit_PWMServoDriver();');
    } else {
      if (isEsp32) {
        buffer.writeln('#include <ESP32Servo.h>');
      } else {
        buffer.writeln('#include <Servo.h>');
      }
      buffer.writeln('Servo servos[$jointCount];');
    }
    buffer.writeln();

    // 2. Constants & Variables
    buffer.writeln('#define JOINT_COUNT $jointCount');
    buffer.writeln('const int jointPins[JOINT_COUNT] = {$pinArray};');
    buffer.writeln('const int minAngle[JOINT_COUNT] = {$minAngleArray};');
    buffer.writeln('const int maxAngle[JOINT_COUNT] = {$maxAngleArray};');
    
    final defaultAngleArray = profile.joints.map((j) {
      return j.defaultAngle != -1 
          ? j.defaultAngle.toString() 
          : ((j.minAngle + j.maxAngle) ~/ 2).toString();
    }).join(', ');
    buffer.writeln('const int defaultAngle[JOINT_COUNT] = {$defaultAngleArray};');
    
    if (isPca9685) {
      final servoMinArray = profile.joints.map((j) => j.servoMin.toString()).join(', ');
      final servoMaxArray = profile.joints.map((j) => j.servoMax.toString()).join(', ');
      
      buffer.writeln();
      buffer.writeln('/*');
      buffer.writeln(' * KONFIGURASI PULSE HARDWARE (PCA9685, frekuensi 50Hz)');
      buffer.writeln(' * Nilai ini di-generate otomatis dari Robot Profile CORA.');
      buffer.writeln(' * ');
      buffer.writeln(' * Rumus konversi: tick = (microseconds / 20000) x 4096');
      buffer.writeln(' * ');
      buffer.writeln(' * Referensi model servo umum:');
      buffer.writeln(' *   SG90        : servoMin=102, servoMax=492');
      buffer.writeln(' *   MG90S       : servoMin=123, servoMax=492');
      buffer.writeln(' *   MG996R      : servoMin=143, servoMax=471');
      buffer.writeln(' *   DS3225      : servoMin=102, servoMax=512');
      buffer.writeln(' *   HS-645MG    : servoMin=184, servoMax=430');
      buffer.writeln(' *   MG92B       : servoMin=143, servoMax=471');
      buffer.writeln(' * ');
      buffer.writeln(' * Jika servo bergetar di posisi ekstrem atau tidak mencapai');
      buffer.writeln(' * posisi yang diharapkan, sesuaikan nilai per joint di atas');
      buffer.writeln(' * sebesar +/- 5 sampai 15 tick secara bertahap.');
      buffer.writeln(' */');
      buffer.writeln('const int servoMin[JOINT_COUNT] = {$servoMinArray};');
      buffer.writeln('const int servoMax[JOINT_COUNT] = {$servoMaxArray};');
    }
    
    buffer.writeln();
    buffer.writeln('// Smooth Movement Config');
    buffer.writeln('const int stepSize = 1;      // degrees per step');
    buffer.writeln('const int stepDelay = 15;    // ms per step');
    buffer.writeln();
    buffer.writeln('int currentAngle[JOINT_COUNT];');
    buffer.writeln('int targetAngle[JOINT_COUNT];');
    buffer.writeln('unsigned long lastStepTime[JOINT_COUNT];');
    buffer.writeln();
    
    buffer.writeln('String inputBuffer = "";');
    buffer.writeln();
    
    // 3. Helper Functions
    if (isPca9685) {
      buffer.writeln('int derajatKePulse(int derajat, int jointIndex) {');
      buffer.writeln('  return map(derajat, 0, 180, servoMin[jointIndex], servoMax[jointIndex]);');
      buffer.writeln('}');
      buffer.writeln();
      buffer.writeln('void moveServo(int index, int angle) {');
      buffer.writeln('  int safeAngle = constrain(angle, minAngle[index], maxAngle[index]);');
      buffer.writeln('  int pulse = derajatKePulse(safeAngle, index);');
      buffer.writeln('  pwm.setPWM(jointPins[index], 0, pulse);');
      buffer.writeln('}');
    } else {
      buffer.writeln('void moveServo(int index, int angle) {');
      buffer.writeln('  int safeAngle = constrain(angle, minAngle[index], maxAngle[index]);');
      buffer.writeln('  servos[index].write(safeAngle);');
      buffer.writeln('}');
    }
    buffer.writeln();
    
    // 4. Setup
    buffer.writeln('void setup() {');
    if (isEsp32) {
      buffer.writeln('  Serial.begin(115200);');
      buffer.writeln('  SerialBT.begin("${profile.name}");');
      buffer.writeln('  Serial.println("Bluetooth Started! Ready to pair...");');
    } else {
      buffer.writeln('  Serial.begin(9600);');
      buffer.writeln('  Serial.println("Serial Started!");');
    }
    buffer.writeln();
    
    if (isPca9685) {
      buffer.writeln('  pwm.begin();');
      buffer.writeln('  pwm.setPWMFreq(50);');
    } else {
      if (isEsp32) {
        buffer.writeln('  ESP32PWM::allocateTimer(0);');
        buffer.writeln('  ESP32PWM::allocateTimer(1);');
        buffer.writeln('  ESP32PWM::allocateTimer(2);');
        buffer.writeln('  ESP32PWM::allocateTimer(3);');
      }
      buffer.writeln('  for(int i=0; i<JOINT_COUNT; i++) {');
      buffer.writeln('    servos[i].attach(jointPins[i]);');
      buffer.writeln('  }');
    }
    buffer.writeln();
    buffer.writeln('  // Initialize to default angles sequentially (1 second delay between each)');
    buffer.writeln('  for(int i=0; i<JOINT_COUNT; i++) {');
    buffer.writeln('    currentAngle[i] = defaultAngle[i];');
    buffer.writeln('    targetAngle[i] = defaultAngle[i];');
    buffer.writeln('    lastStepTime[i] = 0;');
    buffer.writeln('    moveServo(i, currentAngle[i]);');
    buffer.writeln('    delay(1000); // Wait 1000ms for each servo to reach default position safely');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
    
    // 5. Loop
    buffer.writeln('void processCommand(String cmd) {');
    buffer.writeln('  // Command format: J<index>:<value>');
    buffer.writeln('  if(cmd.startsWith("J")) {');
    buffer.writeln('    int colonIdx = cmd.indexOf(":");');
    buffer.writeln('    if(colonIdx > 1) {');
    buffer.writeln('      int index = cmd.substring(1, colonIdx).toInt();');
    buffer.writeln('      int value = cmd.substring(colonIdx + 1).toInt();');
    buffer.writeln('      if(index >= 0 && index < JOINT_COUNT) {');
    buffer.writeln('        // CONSTRAIN ACTIVE ENFORCEMENT');
    buffer.writeln('        int safeTarget = constrain(value, minAngle[index], maxAngle[index]);');
    buffer.writeln('        targetAngle[index] = safeTarget;');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
    
    buffer.writeln('void loop() {');
    // Serial processing
    if (isEsp32) {
      buffer.writeln('  while(SerialBT.available()) {');
      buffer.writeln('    char c = SerialBT.read();');
    } else {
      buffer.writeln('  while(Serial.available()) {');
      buffer.writeln('    char c = Serial.read();');
    }
    buffer.writeln('    if(c == \'\\n\') {');
    buffer.writeln('      processCommand(inputBuffer);');
    buffer.writeln('      inputBuffer = "";');
    buffer.writeln('    } else if (c != \'\\r\') {');
    buffer.writeln('      inputBuffer += c;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
    
    // Smooth movement interpolation
    buffer.writeln('  unsigned long currentMillis = millis();');
    buffer.writeln('  for(int i=0; i<JOINT_COUNT; i++) {');
    buffer.writeln('    if(currentAngle[i] != targetAngle[i]) {');
    buffer.writeln('      if(currentMillis - lastStepTime[i] >= stepDelay) {');
    buffer.writeln('        lastStepTime[i] = currentMillis;');
    buffer.writeln('        ');
    buffer.writeln('        if(currentAngle[i] < targetAngle[i]) {');
    buffer.writeln('          currentAngle[i] += stepSize;');
    buffer.writeln('          if(currentAngle[i] > targetAngle[i]) currentAngle[i] = targetAngle[i];');
    buffer.writeln('        } else {');
    buffer.writeln('          currentAngle[i] -= stepSize;');
    buffer.writeln('          if(currentAngle[i] < targetAngle[i]) currentAngle[i] = targetAngle[i];');
    buffer.writeln('        }');
    buffer.writeln('        ');
    buffer.writeln('        moveServo(i, currentAngle[i]);');
    buffer.writeln('      }');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln('}');
    
    return buffer.toString();
  }
}
