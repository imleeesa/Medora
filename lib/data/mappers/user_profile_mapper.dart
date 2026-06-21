import 'package:drift/drift.dart';

import '../../models/app_settings.dart' as app_settings;
import '../../models/user_profile.dart' as app;
import '../local_database.dart' as db;

class UserProfileMapper {
  const UserProfileMapper._();

  static app.UserProfile fromDatabase(
    db.UserProfile profile, {
    app_settings.AppSettings? settings,
  }) {
    return app.UserProfile(
      id: profile.id,
      name: profile.name,
      photoUrl: profile.avatarPath,
      isDarkMode: settings?.isDarkMode ?? false,
      notificationsEnabled: settings?.notificationsEnabled ?? true,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }

  static db.UserProfilesCompanion toCompanion(app.UserProfile profile) {
    return db.UserProfilesCompanion.insert(
      id: profile.id,
      name: profile.name,
      avatarPath: Value(profile.photoUrl),
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }
}
