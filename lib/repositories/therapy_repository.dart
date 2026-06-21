import 'package:drift/drift.dart';

import '../data/database_service.dart';
import '../data/local_database.dart';

class TherapyRepository {
  TherapyRepository({DatabaseService? databaseService})
    : _database = (databaseService ?? DatabaseService.instance).database;

  final LocalDatabase _database;

  Stream<List<Therapy>> watchTherapies(String profileId) {
    final query = _database.select(_database.therapies)
      ..where((therapy) => therapy.profileId.equals(profileId))
      ..orderBy([(therapy) => OrderingTerm.asc(therapy.name)]);
    return query.watch();
  }

  Future<List<Therapy>> getTherapies(String profileId) {
    final query = _database.select(_database.therapies)
      ..where((therapy) => therapy.profileId.equals(profileId))
      ..orderBy([(therapy) => OrderingTerm.asc(therapy.name)]);
    return query.get();
  }

  Future<void> createTherapy(TherapiesCompanion therapy) async {
    await _database.into(_database.therapies).insert(therapy);
  }

  Future<bool> updateTherapy(TherapiesCompanion therapy) {
    return _database.update(_database.therapies).replace(therapy);
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
