import 'package:hive_flutter/hive_flutter.dart';
import '../models/robot_profile.dart';

class ProfileRepository {
  static const String boxName = 'robot_profiles';
  static const String activeProfileKey = 'active_profile_id';
  
  Box<RobotProfile>? _box;
  Box? _settingsBox;

  Future<void> init() async {
    _box = await Hive.openBox<RobotProfile>(boxName);
    _settingsBox = await Hive.openBox('settings');
  }

  List<RobotProfile> getProfiles() {
    return _box?.values.toList() ?? [];
  }

  Future<void> addProfile(RobotProfile profile) async {
    await _box?.put(profile.id, profile);
  }

  Future<void> updateProfile(RobotProfile profile) async {
    await profile.save();
  }

  Future<void> deleteProfile(String id) async {
    await _box?.delete(id);
    
    // If the active profile is deleted, clear the active profile id
    final activeId = _settingsBox?.get(activeProfileKey);
    if (activeId == id) {
      await _settingsBox?.delete(activeProfileKey);
      
      // We should also set isActive to false on the object itself just in case
      final profile = _box?.get(id);
      if (profile != null) {
        profile.isActive = false;
        await profile.save();
      }
    }
  }

  Future<void> setActiveProfile(String id) async {
    final profiles = getProfiles();
    for (var profile in profiles) {
      if (profile.id == id) {
        profile.isActive = true;
      } else {
        profile.isActive = false;
      }
      await profile.save();
    }
    await _settingsBox?.put(activeProfileKey, id);
  }

  RobotProfile? getActiveProfile() {
    final activeId = _settingsBox?.get(activeProfileKey);
    if (activeId != null) {
      return _box?.get(activeId);
    }
    // Fallback if no active id is saved but one profile is marked active
    final profiles = getProfiles();
    try {
      return profiles.firstWhere((p) => p.isActive);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearAll() async {
    await _box?.clear();
    await _settingsBox?.clear();
  }
}
