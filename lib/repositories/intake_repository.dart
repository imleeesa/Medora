import 'package:drift/drift.dart';

import '../data/database_service.dart';
import '../data/local_database.dart';
import '../data/mappers/intake_record_mapper.dart';
import '../data/mappers/medicine_mapper.dart';
import '../models/intake_record.dart' as app;
import '../models/medicine.dart' as app_medicine;

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

  Future<app.IntakeRecord?> getIntakeRecordForSchedule({
    required String medicineId,
    required DateTime scheduledDateTime,
  }) async {
    final query = _database.select(_database.intakeRecords)
      ..where(
        (record) =>
            record.medicineId.equals(medicineId) &
            record.scheduledDateTime.equals(scheduledDateTime),
      )
      ..limit(1);
    final record = await query.getSingleOrNull();
    return record == null ? null : IntakeRecordMapper.fromDatabase(record);
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

  Future<void> saveIntakeRecordWithStock({
    required app.IntakeRecord record,
    required bool updateExistingRecord,
    app_medicine.Medicine? updatedMedicine,
  }) async {
    await _database.transaction(() async {
      if (updatedMedicine != null) {
        final medicineUpdated = await _database
            .update(_database.medicines)
            .replace(MedicineMapper.toCompanion(updatedMedicine));
        if (!medicineUpdated) {
          throw StateError('Impossibile aggiornare la scorta della medicina.');
        }
      }

      if (updateExistingRecord) {
        final recordUpdated = await _database
            .update(_database.intakeRecords)
            .replace(IntakeRecordMapper.toCompanion(record));
        if (!recordUpdated) {
          throw StateError(
            'Impossibile aggiornare lo storico dell\'assunzione.',
          );
        }
      } else {
        await _database
            .into(_database.intakeRecords)
            .insert(IntakeRecordMapper.toCompanion(record));
      }
    });
  }
}
