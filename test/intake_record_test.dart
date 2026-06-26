import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/intake_record.dart';

void main() {
  test('preserves legacy missed records as missed', () {
    final record = IntakeRecord.fromJson({
      'id': 'record-1',
      'medicineId': 'medicine-1',
      'profileId': 'local-user',
      'scheduledDateTime': '2026-06-24T08:00:00.000',
      'actualDateTime': null,
      'status': 'missed',
      'medicineNameSnapshot': 'Medicina di prova',
      'medicineDoseSnapshot': '',
    });

    expect(record.status, IntakeStatus.missed);
    expect(record.doseLabel, 'Dose non specificata');
  });

  test('clears the actual time when an intake is marked as skipped', () {
    final record = IntakeRecord(
      id: 'record-1',
      medicineId: 'medicine-1',
      profileId: 'local-user',
      scheduledDateTime: DateTime(2026, 6, 24, 8),
      actualDateTime: DateTime(2026, 6, 24, 8, 5),
      status: IntakeStatus.taken,
      medicineNameSnapshot: 'Medicina di prova',
    );

    final skipped = record.copyWith(
      status: IntakeStatus.skipped,
      clearActualDateTime: true,
    );

    expect(skipped.status, IntakeStatus.skipped);
    expect(skipped.actualDateTime, isNull);
  });
}
