import '../../models/app_settings.dart' as app;
import '../local_database.dart' as db;

class SettingsMapper {
  const SettingsMapper._();

  static app.AppSettings fromDatabase(db.AppSetting settings) {
    return app.AppSettings(
      id: settings.id,
      profileId: settings.profileId,
      themeMode: settings.themeMode,
      notificationsEnabled: settings.notificationsEnabled,
      createdAt: settings.createdAt,
      updatedAt: settings.updatedAt,
    );
  }

  static db.AppSettingsCompanion toCompanion(app.AppSettings settings) {
    return db.AppSettingsCompanion.insert(
      id: settings.id,
      profileId: settings.profileId,
      themeMode: settings.themeMode,
      notificationsEnabled: settings.notificationsEnabled,
      createdAt: settings.createdAt,
      updatedAt: settings.updatedAt,
    );
  }
}
