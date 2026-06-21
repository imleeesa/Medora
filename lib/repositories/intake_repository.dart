import 'package:drift/drift.dart';

import '../data/database_service.dart';
import '../data/local_database.dart';

class IntakeRepository {
  IntakeRepository({DatabaseService? databaseService})
    : _database = (databaseService ?? DatabaseService.instance).database;

  final LocalDatabase _database;

  Future<List<IntakeRecord>> getIntakeRecords(String profileId) {
    final query = _database.select(_database.intakeRecords)
      ..where((record) => record.profileId.equals(profileId))
      ..orderBy([(record) => OrderingTerm.desc(record.scheduledDateTime)]);
    return query.get();
  }

  Future<List<IntakeRecord>> getIntakeRecordsByMedicine(String medicineId) {
    final query = _database.select(_database.intakeRecords)
      ..where((record) => record.medicineId.equals(medicineId))
      ..orderBy([(record) => OrderingTerm.desc(record.scheduledDateTime)]);
    return query.get();
  }

  Future<void> createIntakeRecord(IntakeRecordsCompanion record) async {
    await _database.into(_database.intakeRecords).insert(record);
  }

  Future<bool> updateIntakeRecord(IntakeRecordsCompanion record) {
    return _database.update(_database.intakeRecords).replace(record);
  }
}
