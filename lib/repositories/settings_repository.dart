import '../data/database_service.dart';
import '../data/local_database.dart';
import '../data/mappers/settings_mapper.dart';
import '../models/app_settings.dart' as app;

class SettingsRepository {
  SettingsRepository({DatabaseService? databaseService})
    : _database = (databaseService ?? DatabaseService.instance).database;

  final LocalDatabase _database;

  Future<app.AppSettings?> getSettingsForProfile(String profileId) async {
    final query = _database.select(_database.appSettings)
      ..where((settings) => settings.profileId.equals(profileId));
    final settings = await query.getSingleOrNull();
    return settings == null ? null : SettingsMapper.fromDatabase(settings);
  }

  Future<void> updateSettings(app.AppSettings settings) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(SettingsMapper.toCompanion(settings));
  }
}
