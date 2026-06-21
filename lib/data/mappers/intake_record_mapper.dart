import 'package:drift/drift.dart';

import '../../models/intake_record.dart' as app;
import '../local_database.dart' as db;

class IntakeRecordMapper {
  const IntakeRecordMapper._();

  static app.IntakeRecord fromDatabase(db.IntakeRecord record) {
    return app.IntakeRecord(
      id: record.id,
      medicineId: record.medicineId,
      profileId: record.profileId,
      scheduledDateTime: record.scheduledDateTime,
      actualDateTime: record.actualDateTime,
      status: _statusFromDatabase(record.status),
      notes: record.notes,
      medicineNameSnapshot: record.medicineNameSnapshot,
      medicineDoseSnapshot: record.medicineDoseSnapshot,
      createdAt: record.createdAt,
    );
  }

  static db.IntakeRecordsCompanion toCompanion(app.IntakeRecord record) {
    final profileId = record.profileId;
    if (profileId == null) {
      throw StateError(
        'An intake record must have a profileId before persistence.',
      );
    }

    return db.IntakeRecordsCompanion.insert(
      id: record.id,
      medicineId: Value(record.medicineId),
      profileId: profileId,
      scheduledDateTime: record.scheduledDateTime,
      actualDateTime: Value(record.actualDateTime),
      status: _statusToDatabase(record.status),
      notes: Value(record.notes),
      medicineNameSnapshot: record.medicineNameSnapshot,
      medicineDoseSnapshot: record.medicineDoseSnapshot,
      createdAt: record.createdAt,
    );
  }

  static app.IntakeStatus _statusFromDatabase(String status) {
    return switch (status) {
      'taken' => app.IntakeStatus.taken,
      'missed' => app.IntakeStatus.missed,
      'skipped' => app.IntakeStatus.skipped,
      _ => throw ArgumentError.value(
        status,
        'status',
        'Unsupported intake status.',
      ),
    };
  }

  static String _statusToDatabase(app.IntakeStatus status) {
    return switch (status) {
      app.IntakeStatus.taken => 'taken',
      app.IntakeStatus.missed => 'missed',
      app.IntakeStatus.skipped => 'skipped',
    };
  }
}
