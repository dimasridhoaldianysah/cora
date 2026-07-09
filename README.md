# CORA (Controller Robotic Arm)

CORA is a comprehensive Flutter-based companion application designed to control, train (Teach & Record), and automate DIY robotic arms via Bluetooth. Built with modern UI/UX principles (Material 3), CORA supports multiple boards, drivers, and connection protocols to provide a flexible and powerful robotic control experience.

## Features

- **Multi-Board Support**: Compatible with Arduino Uno, Arduino Nano, and ESP32 platforms.
- **Dual Connectivity**: Supports both Bluetooth Classic (HC-05) and Bluetooth Low Energy (BLE).
- **Servo Driver Flexibility**: Works with Direct Pin connections (via `Servo.h` / `ESP32Servo.h`) and PCA9685 I2C 16-channel drivers.
- **Teach & Record**: Manually position the arm, save poses, and play them back in sequence with dynamic movement delays based on angular delta.
- **Automated Firmware Generation**: Generates ready-to-upload C++ (`.ino`) firmware customized for your specific robot profile (pins, angles, board type, and driver).
- **Robot Profiles**: Manage multiple robotic arm configurations within a single app.
- **Modern Interface**: Deep space blue theme, semantic color indicators, and full-screen immersive mode for a distraction-free control environment.

## Getting Started

### Prerequisites

- Flutter SDK (v3.10.0 or higher)
- Dart SDK (v3.0.0 or higher)
- Android Studio or VS Code for development
- An Android device (minimum SDK 21) for deployment

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/dimasridhoaldianysah/cora.git
   ```
2. Navigate to the project directory:
   ```bash
   cd cora
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Build the application for Android:
   ```bash
   flutter build apk --release
   ```

## How to Use CORA (Tutorial)

Follow these steps to fully configure and automate your DIY robotic arm:

### 1. Create a Robot Profile
1. Open the **Profiles** menu from the side drawer.
2. Tap the **+** button to create a new profile.
3. Define your hardware: Choose your Board (Arduino Uno, Nano, or ESP32), select the Servo Driver (Direct Pin or PCA9685), and set the number of joints.
4. Configure each joint: Assign the correct hardware Pin/Channel, set Minimum and Maximum Angles, and define the Default starting angle.
5. Save the profile and tap on it in the list to mark it as **Active**.

### 2. Generate and Upload Firmware
1. Navigate to the **Firmware** menu.
2. The app will automatically generate custom C++ (`.ino`) code based on your active profile's specifications.
3. Tap **Export ZIP** to save the code to your phone.
4. Transfer the ZIP file to your PC, extract it, and upload it to your microcontroller using the Arduino IDE.

### 3. Connect via Bluetooth
1. Ensure your robotic arm is powered on and the Bluetooth module is ready.
2. Tap the **Bluetooth icon** on the top right corner of the app.
3. Select your connection type: **Classic** (for HC-05/HC-06 modules) or **BLE** (for built-in ESP32 Bluetooth).
4. Tap your device from the list. The top-right indicator will turn **Green** once successfully connected.

### 4. Control and Automate (Teach & Record)
1. Navigate to the **Control** menu.
2. **Manual Control:** Move the sliders to precisely position each joint of your robotic arm.
3. **Teach & Record:** 
   - Position the arm to a desired starting pose and press **Save**.
   - Move the arm to the next position and press **Save** again.
   - Repeat this for your entire sequence.
4. **Playback:** Press **Play** to watch the robotic arm automatically execute the saved sequence. Toggle **Loop** if you want the sequence to repeat indefinitely. Press **Stop** to halt playback or **Reset** to clear the saved memory.

## Architecture Overview

CORA utilizes a layered architecture powered by **Riverpod** for state management and **Hive** for local NoSQL data storage.

- **Presentation Layer**: UI screens and components utilizing `go_router` for declarative navigation.
- **State Management Layer (`providers/`)**: 
  - `bt_provider`: Manages Bluetooth connection state and serial communication.
  - `control_provider`: Manages joint angles and real-time slider updates.
  - `pose_provider`: Handles the Teach & Record logic and dynamic playback delay estimation.
  - `profile_provider`: Manages the active robot profile and Hive repository interactions.
- **Service Layer (`services/`)**: Contains abstractions for Bluetooth Classic, BLE, and the dynamic firmware generator.
- **Data Layer (`data/`)**: Hive models (`RobotProfile`, `JointConfig`) and repository logic.

## Firmware Generation Protocol

The app communicates with the microcontroller using a simple text-based serial protocol:
```
J<joint_index>:<target_angle>\n
```
Example: `J0:90\n` moves joint 0 to 90 degrees.
The integrated firmware generator automatically constructs the C++ parsing logic and smooth interpolation loops for the target board.

## Contribution

Contributions are welcome! If you'd like to improve CORA or add support for new microcontrollers/drivers, please open an issue or submit a pull request.

## Development Team (Tim CORA)
* **Dimas Ridho Aldiansyah** - Lead Developer & Mobile Engineer.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
