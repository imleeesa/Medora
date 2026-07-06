import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/intake_record.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/models/therapy.dart';
import 'package:meditrack/services/history_statistics_service.dart';

void main() {
  final referenceDate = DateTime(2026, 7, 6, 12);
  final therapies = [
    _therapy(
      id: 'therapy-a',
      name: 'Antibiotico',
      medicines: [
        _medicine(id: 'medicine-a', name: 'Tachis', therapyId: 'therapy-a'),
      ],
    ),
    _therapy(
      id: 'therapy-b',
      name: 'Integratori',
      medicines: [
        _medicine(id: 'medicine-b', name: 'Vitamina D', therapyId: 'therapy-b'),
      ],
    ),
  ];

  HistoryStatisticsSummary summary({
    required List<IntakeRecord> records,
    required List<Therapy> therapies,
  }) {
    return HistoryStatisticsService.calculate(
      records: records,
      therapies: therapies,
      referenceDate: referenceDate,
    );
  }

  test('returns zero statistics for an empty history', () {
    final result = summary(records: const [], therapies: therapies);

    expect(result.all.totalRecords, 0);
    expect(result.all.adherenceDenominator, 0);
    expect(result.all.adherencePercent, 0);
    expect(result.byMedicine, isEmpty);
    expect(result.byTherapy, isEmpty);
  });

  test('calculates full adherence when every record is taken', () {
    final result = summary(
      records: [
        _record(
          id: 'taken-1',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 8),
          status: IntakeStatus.taken,
        ),
      ],
      therapies: therapies,
    );

    expect(result.all.taken, 1);
    expect(result.all.skipped, 0);
    expect(result.all.missed, 0);
    expect(result.all.adherencePercent, 100);
  });

  test('calculates adherence with taken, skipped and missed records', () {
    final result = summary(
      records: [
        _record(
          id: 'taken-1',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 8),
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'skipped-1',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 5, 8),
          status: IntakeStatus.skipped,
        ),
        _record(
          id: 'missed-1',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 4, 8),
          status: IntakeStatus.missed,
        ),
      ],
      therapies: therapies,
    );

    expect(result.all.totalRecords, 3);
    expect(result.all.adherenceDenominator, 3);
    expect(result.all.adherencePercent, 33);
  });

  test('ignores scheduled records in adherence denominator', () {
    final result = summary(
      records: [
        _record(
          id: 'scheduled-1',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 8),
          status: IntakeStatus.scheduled,
        ),
      ],
      therapies: therapies,
    );

    expect(result.all.totalRecords, 1);
    expect(result.all.adherenceDenominator, 0);
    expect(result.all.adherencePercent, 0);
  });

  test('calculates today, last 7 days and last 30 days windows', () {
    final result = summary(
      records: [
        _record(
          id: 'today',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 8),
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'seven-days',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 6, 30, 8),
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'thirty-days',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 6, 7, 8),
          status: IntakeStatus.skipped,
        ),
        _record(
          id: 'old',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 6, 6, 8),
          status: IntakeStatus.missed,
        ),
      ],
      therapies: therapies,
    );

    expect(result.today.totalRecords, 1);
    expect(result.last7Days.totalRecords, 2);
    expect(result.last30Days.totalRecords, 3);
    expect(result.all.totalRecords, 4);
  });

  test(
    'groups statistics by current medicine and deleted medicine snapshot',
    () {
      final result = summary(
        records: [
          _record(
            id: 'current',
            medicineId: 'medicine-a',
            medicineName: 'Tachis old',
            scheduledDateTime: DateTime(2026, 7, 6, 8),
            status: IntakeStatus.taken,
          ),
          _record(
            id: 'deleted',
            medicineId: null,
            medicineName: 'Medicina eliminata',
            scheduledDateTime: DateTime(2026, 7, 6, 9),
            status: IntakeStatus.missed,
          ),
        ],
        therapies: therapies,
      );

      expect(result.byMedicine.map((item) => item.name), contains('Tachis'));
      final deleted = result.byMedicine.firstWhere(
        (item) => item.name == 'Medicina eliminata',
      );
      expect(deleted.isDeleted, isTrue);
      expect(deleted.statistics.missed, 1);
    },
  );

  test(
    'groups statistics by therapy when the medicine is still attributable',
    () {
      final result = summary(
        records: [
          _record(
            id: 'therapy-a',
            medicineId: 'medicine-a',
            medicineName: 'Tachis',
            scheduledDateTime: DateTime(2026, 7, 6, 8),
            status: IntakeStatus.taken,
          ),
          _record(
            id: 'therapy-b',
            medicineId: 'medicine-b',
            medicineName: 'Vitamina D',
            scheduledDateTime: DateTime(2026, 7, 6, 9),
            status: IntakeStatus.skipped,
          ),
          _record(
            id: 'deleted',
            medicineId: null,
            medicineName: 'Medicina eliminata',
            scheduledDateTime: DateTime(2026, 7, 6, 10),
            status: IntakeStatus.taken,
          ),
        ],
        therapies: therapies,
      );

      expect(
        result.byTherapy.map((item) => item.name),
        contains('Antibiotico'),
      );
      expect(
        result.byTherapy.map((item) => item.name),
        contains('Integratori'),
      );
      expect(result.unattributedTherapyRecords, 1);
    },
  );
}

Therapy _therapy({
  required String id,
  required String name,
  required List<Medicine> medicines,
}) {
  return Therapy(id: id, name: name, color: '#2E7D32', medicines: medicines);
}

Medicine _medicine({
  required String id,
  required String name,
  required String therapyId,
}) {
  final now = DateTime(2026, 7, 1);
  return Medicine(
    id: id,
    name: name,
    therapyId: therapyId,
    dose: '1 compressa',
    times: const [TimeOfDay(hour: 8, minute: 0)],
    daysOfWeek: const [DateTime.monday],
    stockQuantity: 10,
    stockWarningThreshold: 2,
    createdAt: now,
    updatedAt: now,
  );
}

IntakeRecord _record({
  required String id,
  required String? medicineId,
  required String medicineName,
  required DateTime scheduledDateTime,
  required IntakeStatus status,
}) {
  return IntakeRecord(
    id: id,
    medicineId: medicineId,
    profileId: 'profile-1',
    scheduledDateTime: scheduledDateTime,
    actualDateTime: status == IntakeStatus.taken ? scheduledDateTime : null,
    status: status,
    medicineNameSnapshot: medicineName,
    medicineDoseSnapshot: '1 compressa',
  );
}
