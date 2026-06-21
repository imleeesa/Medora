import 'package:drift/drift.dart';

import '../data/database_service.dart';
import '../data/local_database.dart';
import '../data/mappers/intake_record_mapper.dart';
import '../models/intake_record.dart' as app;

class IntakeRepository {
  IntakeRepository({DatabaseService? databaseService})
    : _database = (databaseService ?? DatabaseService.instance).database;

  final LocalDatabase _database;

  Future<List<app.IntakeRecord>> getIntakeRecords(String profileId) async {
    final query = _database.select(_database.intakeRecords)
      ..where((record) => record.profileId.equals(profileId))
      ..orderBy([(record) => OrderingTerm.desc(record.scheduledDateTime)]);
    final records = await query.get();
    return records.map(IntakeRecordMapper.fromDatabase).toList();
  }

  Future<List<app.IntakeRecord>> getIntakeRecordsByMedicine(
    String medicineId,
  ) async {
    final query = _database.select(_database.intakeRecords)
      ..where((record) => record.medicineId.equals(medicineId))
      ..orderBy([(record) => OrderingTerm.desc(record.scheduledDateTime)]);
    final records = await query.get();
    return records.map(IntakeRecordMapper.fromDatabase).toList();
  }

  Future<void> createIntakeRecord(app.IntakeRecord record) async {
    await _database
        .into(_database.intakeRecords)
        .insert(IntakeRecordMapper.toCompanion(record));
  }

  Future<bool> updateIntakeRecord(app.IntakeRecord record) {
    return _database
        .update(_database.intakeRecords)
        .replace(IntakeRecordMapper.toCompanion(record));
  }
}
