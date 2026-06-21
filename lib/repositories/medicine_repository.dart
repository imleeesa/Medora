import 'package:drift/drift.dart';

import '../data/database_service.dart';
import '../data/local_database.dart';
import '../data/mappers/medicine_mapper.dart';
import '../models/medicine.dart' as app;
import '../models/medicine_schedule.dart' as app_schedule;

class MedicineRepository {
  MedicineRepository({DatabaseService? databaseService})
    : _database = (databaseService ?? DatabaseService.instance).database;

  final LocalDatabase _database;

  Stream<List<app.Medicine>> watchMedicines(String profileId) {
    final query =
        _database.select(_database.medicines).join([
            leftOuterJoin(
              _database.medicineSchedules,
              _database.medicineSchedules.medicineId.equalsExp(
                _database.medicines.id,
              ),
            ),
          ])
          ..where(_database.medicines.profileId.equals(profileId))
          ..orderBy([
            OrderingTerm.asc(_database.medicines.name),
            OrderingTerm.asc(_database.medicineSchedules.hour),
            OrderingTerm.asc(_database.medicineSchedules.minute),
          ]);
    return query.watch().map(_mapJoinedMedicines);
  }

  Future<List<app.Medicine>> getMedicines(String profileId) async {
    final query = _database.select(_database.medicines)
      ..where((medicine) => medicine.profileId.equals(profileId))
      ..orderBy([(medicine) => OrderingTerm.asc(medicine.name)]);
    return _toMedicines(await query.get());
  }

  Future<List<app.Medicine>> getMedicinesByTherapy(String therapyId) async {
    final query = _database.select(_database.medicines)
      ..where((medicine) => medicine.therapyId.equals(therapyId))
      ..orderBy([(medicine) => OrderingTerm.asc(medicine.name)]);
    return _toMedicines(await query.get());
  }

  Future<void> createMedicine(app.Medicine medicine) async {
    await _database.transaction(() async {
      await _database
          .into(_database.medicines)
          .insert(MedicineMapper.toCompanion(medicine));
      await _replaceSchedules(medicine.id, medicine.schedules);
    });
  }

  Future<bool> updateMedicine(app.Medicine medicine) async {
    var updated = false;
    await _database.transaction(() async {
      updated = await _database
          .update(_database.medicines)
          .replace(MedicineMapper.toCompanion(medicine));
      if (updated) {
        await _replaceSchedules(medicine.id, medicine.schedules);
      }
    });
    return updated;
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

  Future<List<app.Medicine>> getLowStockMedicines(String profileId) async {
    final medicines = await getMedicines(profileId);
    return medicines
        .where(
          (medicine) =>
              medicine.stockQuantity <= medicine.stockWarningThreshold,
        )
        .toList(growable: false);
  }

  Future<List<app_schedule.MedicineSchedule>> getSchedulesForMedicine(
    String medicineId,
  ) async {
    final query = _database.select(_database.medicineSchedules)
      ..where((schedule) => schedule.medicineId.equals(medicineId))
      ..orderBy([
        (schedule) => OrderingTerm.asc(schedule.dayOfWeek),
        (schedule) => OrderingTerm.asc(schedule.hour),
        (schedule) => OrderingTerm.asc(schedule.minute),
      ]);
    return MedicineMapper.schedulesFromDatabase(await query.get());
  }

  Future<void> replaceSchedules(
    String medicineId,
    List<app_schedule.MedicineSchedule> schedules,
  ) async {
    await _database.transaction(() async {
      await _replaceSchedules(medicineId, schedules);
    });
  }

  Future<List<app.Medicine>> _toMedicines(List<Medicine> medicines) async {
    return Future.wait(
      medicines.map((medicine) async {
        final schedulesQuery = _database.select(_database.medicineSchedules)
          ..where((schedule) => schedule.medicineId.equals(medicine.id));
        final schedules = await schedulesQuery.get();
        return MedicineMapper.fromDatabase(medicine, schedules);
      }),
    );
  }

  Future<void> _replaceSchedules(
    String medicineId,
    List<app_schedule.MedicineSchedule> schedules,
  ) async {
    await (_database.delete(
      _database.medicineSchedules,
    )..where((schedule) => schedule.medicineId.equals(medicineId))).go();
    final companions = MedicineMapper.toScheduleCompanions(
      medicineId,
      schedules,
    );
    if (companions.isNotEmpty) {
      await _database.batch((batch) {
        batch.insertAll(_database.medicineSchedules, companions);
      });
    }
  }

  List<app.Medicine> _mapJoinedMedicines(List<TypedResult> rows) {
    final medicinesById = <String, Medicine>{};
    final schedulesByMedicineId = <String, List<MedicineSchedule>>{};

    for (final row in rows) {
      final medicine = row.readTable(_database.medicines);
      final schedule = row.readTableOrNull(_database.medicineSchedules);
      medicinesById.putIfAbsent(medicine.id, () => medicine);
      if (schedule != null) {
        schedulesByMedicineId.putIfAbsent(medicine.id, () => []).add(schedule);
      }
    }

    return medicinesById.values
        .map(
          (medicine) => MedicineMapper.fromDatabase(
            medicine,
            schedulesByMedicineId[medicine.id] ?? const [],
          ),
        )
        .toList(growable: false);
  }
}
