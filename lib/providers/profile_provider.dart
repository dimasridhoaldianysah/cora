import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/models/robot_profile.dart';
import '../data/repositories/profile_repository.dart';

// Provides a singleton instance of the repository
final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  throw UnimplementedError('profileRepositoryProvider must be overridden in ProviderScope');
});

// State class for ProfileProvider
class ProfileState {
  final List<RobotProfile> profiles;
  final RobotProfile? activeProfile;

  ProfileState({
    this.profiles = const [],
    this.activeProfile,
  });

  ProfileState copyWith({
    List<RobotProfile>? profiles,
    RobotProfile? activeProfile,
  }) {
    return ProfileState(
      profiles: profiles ?? this.profiles,
      activeProfile: activeProfile ?? this.activeProfile,
    );
  }
}

// The Profile Notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileRepository repository;

  ProfileNotifier(this.repository) : super(ProfileState()) {
    _loadProfiles();
  }

  void _loadProfiles() {
    final profiles = repository.getProfiles();
    final activeProfile = repository.getActiveProfile();
    state = state.copyWith(profiles: profiles, activeProfile: activeProfile);
  }

  Future<void> addProfile(RobotProfile profile) async {
    // Generate an ID if it's new
    if (profile.id.isEmpty) {
      profile.id = const Uuid().v4();
    }
    await repository.addProfile(profile);
    _loadProfiles();
  }

  Future<void> updateProfile(RobotProfile profile) async {
    await repository.updateProfile(profile);
    _loadProfiles();
  }

  Future<void> deleteProfile(String id) async {
    await repository.deleteProfile(id);
    _loadProfiles();
  }

  Future<void> setActiveProfile(String id) async {
    await repository.setActiveProfile(id);
    _loadProfiles();
  }

  Future<void> clearAll() async {
    await repository.clearAll();
    // Reset state explicitly before _loadProfiles to ensure UI updates instantly
    state = ProfileState(
      profiles: [],
      activeProfile: null,
    );
    _loadProfiles();
  }
}

// The exposed Provider
final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final repo = ref.watch(profileRepositoryProvider);
  return ProfileNotifier(repo);
});
