import 'package:drift/drift.dart';

import '../data/database_service.dart';
import '../data/local_database.dart';
import '../data/mappers/medicine_mapper.dart';
import '../data/mappers/therapy_mapper.dart';
import '../models/medicine.dart' as app_medicine;
import '../models/therapy.dart' as app;

class TherapyRepository {
  TherapyRepository({DatabaseService? databaseService})
    : _database = (databaseService ?? DatabaseService.instance).database;

  final LocalDatabase _database;

  Stream<List<app.Therapy>> watchTherapies(String profileId) {
    final query = _database.select(_database.therapies)
      ..where((therapy) => therapy.profileId.equals(profileId))
      ..orderBy([(therapy) => OrderingTerm.asc(therapy.name)]);
    return query.watch().map(
      (therapies) => therapies.map(TherapyMapper.fromDatabase).toList(),
    );
  }

  Future<List<app.Therapy>> getTherapies(String profileId) async {
    final query = _database.select(_database.therapies)
      ..where((therapy) => therapy.profileId.equals(profileId))
      ..orderBy([(therapy) => OrderingTerm.asc(therapy.name)]);
    final therapies = await query.get();
    return therapies.map(TherapyMapper.fromDatabase).toList();
  }

  Future<void> createTherapy(app.Therapy therapy) async {
    await _database
        .into(_database.therapies)
        .insert(TherapyMapper.toCompanion(therapy));
  }

  Future<void> createTherapyWithMedicine(
    app.Therapy therapy,
    app_medicine.Medicine medicine,
  ) async {
    await _database.transaction(() async {
      await _database
          .into(_database.therapies)
          .insert(TherapyMapper.toCompanion(therapy));
      await _database
          .into(_database.medicines)
          .insert(MedicineMapper.toCompanion(medicine));
      final schedules = MedicineMapper.toScheduleCompanions(
        medicine.id,
        medicine.schedules,
      );
      if (schedules.isNotEmpty) {
        await _database.batch((batch) {
          batch.insertAll(_database.medicineSchedules, schedules);
        });
      }
    });
  }

  Future<bool> updateTherapy(app.Therapy therapy) {
    return _database
        .update(_database.therapies)
        .replace(TherapyMapper.toCompanion(therapy));
  }

  Future<void> deleteTherapy(String therapyId) async {
    await _database.transaction(() async {
      await (_database.update(
        _database.medicines,
      )..where((medicine) => medicine.therapyId.equals(therapyId))).write(
        MedicinesCompanion(
          therapyId: const Value(null),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await (_database.delete(
        _database.therapies,
      )..where((therapy) => therapy.id.equals(therapyId))).go();
    });
  }
}
