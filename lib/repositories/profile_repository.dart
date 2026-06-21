import 'package:drift/drift.dart';

import '../data/database_service.dart';
import '../data/local_database.dart';
import '../data/mappers/settings_mapper.dart';
import '../data/mappers/user_profile_mapper.dart';
import '../models/user_profile.dart' as app;

class ProfileRepository {
  ProfileRepository({DatabaseService? databaseService})
    : _database = (databaseService ?? DatabaseService.instance).database;

  final LocalDatabase _database;

  Future<app.UserProfile?> getCurrentProfile() async {
    final query = _database.select(_database.userProfiles)
      ..orderBy([(profile) => OrderingTerm.desc(profile.updatedAt)])
      ..limit(1);
    final profile = await query.getSingleOrNull();
    return profile == null ? null : _toModel(profile);
  }

  Future<app.UserProfile?> getProfileById(String profileId) async {
    final query = _database.select(_database.userProfiles)
      ..where((profile) => profile.id.equals(profileId));
    final profile = await query.getSingleOrNull();
    return profile == null ? null : _toModel(profile);
  }

  Future<void> createProfile(app.UserProfile profile) async {
    await _database
        .into(_database.userProfiles)
        .insert(UserProfileMapper.toCompanion(profile));
  }

  Future<bool> updateProfile(app.UserProfile profile) {
    return _database
        .update(_database.userProfiles)
        .replace(UserProfileMapper.toCompanion(profile));
  }

  Future<app.UserProfile> _toModel(UserProfile profile) async {
    final settingsQuery = _database.select(_database.appSettings)
      ..where((settings) => settings.profileId.equals(profile.id));
    final settings = await settingsQuery.getSingleOrNull();
    return UserProfileMapper.fromDatabase(
      profile,
      settings: settings == null ? null : SettingsMapper.fromDatabase(settings),
    );
  }
}
