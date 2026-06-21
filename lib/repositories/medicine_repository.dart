import 'package:drift/drift.dart';

import '../data/database_service.dart';
import '../data/local_database.dart';

class MedicineRepository {
  MedicineRepository({DatabaseService? databaseService})
    : _database = (databaseService ?? DatabaseService.instance).database;

  final LocalDatabase _database;

  Stream<List<Medicine>> watchMedicines(String profileId) {
    final query = _database.select(_database.medicines)
      ..where((medicine) => medicine.profileId.equals(profileId))
      ..orderBy([(medicine) => OrderingTerm.asc(medicine.name)]);
    return query.watch();
  }

  Future<List<Medicine>> getMedicines(String profileId) {
    final query = _database.select(_database.medicines)
      ..where((medicine) => medicine.profileId.equals(profileId))
      ..orderBy([(medicine) => OrderingTerm.asc(medicine.name)]);
    return query.get();
  }

  Future<List<Medicine>> getMedicinesByTherapy(String therapyId) {
    final query = _database.select(_database.medicines)
      ..where((medicine) => medicine.therapyId.equals(therapyId))
      ..orderBy([(medicine) => OrderingTerm.asc(medicine.name)]);
    return query.get();
  }

  Future<void> createMedicine(MedicinesCompanion medicine) async {
    await _database.into(_database.medicines).insert(medicine);
  }

  Future<bool> updateMedicine(MedicinesCompanion medicine) {
    return _database.update(_database.medicines).replace(medicine);
  }

  Future<void> deleteMedicine(String medicineId) async {
    await _database.transaction(() async {
      await (_database.update(_database.intakeRecords)
            ..where((record) => record.medicineId.equals(medicineId)))
          .write(const IntakeRecordsCompanion(medicineId: Value(null)));
      await (_database.delete(
        _database.medicineSchedules,
      )..where((schedule) => schedule.medicineId.equals(medicineId))).go();
      await (_database.delete(
        _database.medicines,
      )..where((medicine) => medicine.id.equals(medicineId))).go();
    });
  }

  Future<List<Medicine>> getLowStockMedicines(String profileId) async {
    final medicines = await getMedicines(profileId);
    return medicines
        .where(
          (medicine) =>
              medicine.stockQuantity <= medicine.stockWarningThreshold,
        )
        .toList(growable: false);
  }

  Future<List<MedicineSchedule>> getSchedulesForMedicine(String medicineId) {
    final query = _database.select(_database.medicineSchedules)
      ..where((schedule) => schedule.medicineId.equals(medicineId))
      ..orderBy([
        (schedule) => OrderingTerm.asc(schedule.dayOfWeek),
        (schedule) => OrderingTerm.asc(schedule.hour),
        (schedule) => OrderingTerm.asc(schedule.minute),
      ]);
    return query.get();
  }

  Future<void> replaceSchedules(
    String medicineId,
    List<MedicineSchedulesCompanion> schedules,
  ) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.medicineSchedules,
      )..where((schedule) => schedule.medicineId.equals(medicineId))).go();
      if (schedules.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(_database.medicineSchedules, schedules);
        });
      }
    });
  }
}
