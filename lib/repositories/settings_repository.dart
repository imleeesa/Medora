import '../data/database_service.dart';
import '../data/local_database.dart';

class SettingsRepository {
  SettingsRepository({DatabaseService? databaseService})
    : _database = (databaseService ?? DatabaseService.instance).database;

  final LocalDatabase _database;

  Future<AppSetting?> getSettingsForProfile(String profileId) {
    final query = _database.select(_database.appSettings)
      ..where((settings) => settings.profileId.equals(profileId));
    return query.getSingleOrNull();
  }

  Future<void> updateSettings(AppSettingsCompanion settings) async {
    await _database
        .into(_database.appSettings)
        .insertOnConflictUpdate(settings);
  }
}
