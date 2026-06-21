import 'package:drift/drift.dart';

import '../data/database_service.dart';
import '../data/local_database.dart';

class ProfileRepository {
  ProfileRepository({DatabaseService? databaseService})
    : _database = (databaseService ?? DatabaseService.instance).database;

  final LocalDatabase _database;

  Future<UserProfile?> getCurrentProfile() {
    final query = _database.select(_database.userProfiles)
      ..orderBy([(profile) => OrderingTerm.desc(profile.updatedAt)])
      ..limit(1);
    return query.getSingleOrNull();
  }

  Future<UserProfile?> getProfileById(String profileId) {
    final query = _database.select(_database.userProfiles)
      ..where((profile) => profile.id.equals(profileId));
    return query.getSingleOrNull();
  }

  Future<void> createProfile(UserProfilesCompanion profile) async {
    await _database.into(_database.userProfiles).insert(profile);
  }

  Future<bool> updateProfile(UserProfilesCompanion profile) {
    return _database.update(_database.userProfiles).replace(profile);
  }
}
