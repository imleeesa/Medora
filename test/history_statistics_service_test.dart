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
    expect(result.all.evaluatedRecords, 0);
    expect(result.all.adherencePercent, 0);
  });

  test('includes scheduled records in totals but not evaluated records', () {
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
          id: 'scheduled-1',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 12),
          status: IntakeStatus.scheduled,
        ),
      ],
      therapies: therapies,
    );

    expect(result.all.totalRecords, 2);
    expect(result.all.evaluatedRecords, 1);
    expect(result.all.adherencePercent, 100);
  });

  test('rounds adherence percentage to the nearest integer', () {
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
          id: 'taken-2',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 12),
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'skipped-1',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 20),
          status: IntakeStatus.skipped,
        ),
      ],
      therapies: therapies,
    );

    expect(result.all.adherencePercent, 67);
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

  test('uses day boundaries consistently for today', () {
    final result = summary(
      records: [
        _record(
          id: 'start-of-day',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6),
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'end-of-day',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 23, 59),
          status: IntakeStatus.skipped,
        ),
        _record(
          id: 'yesterday',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 5, 23, 59),
          status: IntakeStatus.missed,
        ),
      ],
      therapies: therapies,
    );

    expect(result.today.totalRecords, 2);
    expect(result.today.evaluatedRecords, 2);
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

  test('uses a safe fallback when a deleted medicine has no snapshot name', () {
    final result = summary(
      records: [
        _record(
          id: 'deleted-no-snapshot',
          medicineId: 'unknown-medicine',
          medicineName: '',
          scheduledDateTime: DateTime(2026, 7, 6, 8),
          status: IntakeStatus.missed,
        ),
      ],
      therapies: therapies,
    );

    expect(result.byMedicine.single.name, 'Medicina non disponibile');
    expect(result.byMedicine.single.isDeleted, isTrue);
    expect(result.byMedicine.single.statistics.missed, 1);
  });

  test('keeps current medicines with the same name separated by id', () {
    final sameNameTherapies = [
      _therapy(
        id: 'therapy-a',
        name: 'Terapia A',
        medicines: [
          _medicine(id: 'medicine-a', name: 'Tachis', therapyId: 'therapy-a'),
        ],
      ),
      _therapy(
        id: 'therapy-b',
        name: 'Terapia B',
        medicines: [
          _medicine(id: 'medicine-b', name: 'Tachis', therapyId: 'therapy-b'),
        ],
      ),
    ];

    final result = summary(
      records: [
        _record(
          id: 'medicine-a-record',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 8),
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'medicine-b-record',
          medicineId: 'medicine-b',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 9),
          status: IntakeStatus.skipped,
        ),
      ],
      therapies: sameNameTherapies,
    );

    expect(result.byMedicine, hasLength(2));
    expect(
      result.byMedicine.map((item) => item.id),
      contains('medicine:medicine-a'),
    );
    expect(
      result.byMedicine.map((item) => item.id),
      contains('medicine:medicine-b'),
    );
  });

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

  test(
    'keeps archived therapies attributable and marks unknown therapy records',
    () {
      final archivedTherapies = [
        _therapy(
          id: 'therapy-archived',
          name: 'Terapia archiviata',
          isActive: false,
          medicines: [
            _medicine(
              id: 'medicine-archived',
              name: 'Medicina archiviata',
              therapyId: 'therapy-archived',
            ),
          ],
        ),
      ];

      final result = summary(
        records: [
          _record(
            id: 'archived-therapy-record',
            medicineId: 'medicine-archived',
            medicineName: 'Medicina archiviata',
            scheduledDateTime: DateTime(2026, 7, 6, 8),
            status: IntakeStatus.taken,
          ),
          _record(
            id: 'unknown-therapy-record',
            medicineId: 'unknown-medicine',
            medicineName: 'Medicina eliminata',
            scheduledDateTime: DateTime(2026, 7, 6, 9),
            status: IntakeStatus.missed,
          ),
        ],
        therapies: archivedTherapies,
      );

      expect(result.byTherapy.single.name, 'Terapia archiviata');
      expect(result.byTherapy.single.statistics.taken, 1);
      expect(result.unattributedTherapyRecords, 1);
    },
  );

  test('builds a chronological 7 day adherence trend', () {
    final trend = HistoryStatisticsService.adherenceTrend(
      records: [
        _record(
          id: 'first-day',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 6, 30, 8),
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'last-day',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 8),
          status: IntakeStatus.skipped,
        ),
      ],
      therapies: therapies,
      referenceDate: referenceDate,
      period: AdherenceTrendPeriod.last7Days,
    );

    expect(trend, hasLength(7));
    expect(trend.first.date, DateTime(2026, 6, 30));
    expect(trend.last.date, DateTime(2026, 7, 6));
    expect(trend.first.adherencePercent, 100);
    expect(trend.last.adherencePercent, 0);
  });

  test(
    'builds a 30 day trend and leaves days without evaluated data empty',
    () {
      final trend = HistoryStatisticsService.adherenceTrend(
        records: [
          _record(
            id: 'thirty-days',
            medicineId: 'medicine-a',
            medicineName: 'Tachis',
            scheduledDateTime: DateTime(2026, 6, 7, 8),
            status: IntakeStatus.taken,
          ),
        ],
        therapies: therapies,
        referenceDate: referenceDate,
        period: AdherenceTrendPeriod.last30Days,
      );

      expect(trend, hasLength(30));
      expect(trend.first.date, DateTime(2026, 6, 7));
      expect(trend.first.adherencePercent, 100);
      expect(trend[1].evaluatedRecords, 0);
      expect(trend[1].adherencePercent, isNull);
    },
  );

  test(
    'calculates daily 50 percent and excludes scheduled records from trend',
    () {
      final trend = HistoryStatisticsService.adherenceTrend(
        records: [
          _record(
            id: 'taken',
            medicineId: 'medicine-a',
            medicineName: 'Tachis',
            scheduledDateTime: DateTime(2026, 7, 6, 8),
            status: IntakeStatus.taken,
          ),
          _record(
            id: 'skipped',
            medicineId: 'medicine-a',
            medicineName: 'Tachis',
            scheduledDateTime: DateTime(2026, 7, 6, 12),
            status: IntakeStatus.skipped,
          ),
          _record(
            id: 'scheduled',
            medicineId: 'medicine-a',
            medicineName: 'Tachis',
            scheduledDateTime: DateTime(2026, 7, 6, 20),
            status: IntakeStatus.scheduled,
          ),
        ],
        therapies: therapies,
        referenceDate: referenceDate,
        period: AdherenceTrendPeriod.last7Days,
      );

      expect(trend.last.evaluatedRecords, 2);
      expect(trend.last.adherencePercent, 50);
    },
  );

  test('filters trend by medicine id', () {
    final trend = HistoryStatisticsService.adherenceTrend(
      records: [
        _record(
          id: 'medicine-a',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 8),
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'medicine-b',
          medicineId: 'medicine-b',
          medicineName: 'Vitamina D',
          scheduledDateTime: DateTime(2026, 7, 6, 9),
          status: IntakeStatus.missed,
        ),
      ],
      therapies: therapies,
      referenceDate: referenceDate,
      period: AdherenceTrendPeriod.last7Days,
      medicineId: 'medicine-b',
    );

    expect(trend.last.taken, 0);
    expect(trend.last.missed, 1);
    expect(trend.last.adherencePercent, 0);
  });

  test('filters trend by deleted medicine snapshot', () {
    final trend = HistoryStatisticsService.adherenceTrend(
      records: [
        _record(
          id: 'current',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
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
      referenceDate: referenceDate,
      period: AdherenceTrendPeriod.last7Days,
      medicineSnapshotName: 'Medicina eliminata',
    );

    expect(trend.last.taken, 0);
    expect(trend.last.missed, 1);
    expect(trend.last.adherencePercent, 0);
  });

  test('filters trend by therapy without attributing unknown records', () {
    final trend = HistoryStatisticsService.adherenceTrend(
      records: [
        _record(
          id: 'therapy-a',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 6, 8),
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'unknown',
          medicineId: null,
          medicineName: 'Medicina eliminata',
          scheduledDateTime: DateTime(2026, 7, 6, 9),
          status: IntakeStatus.missed,
        ),
      ],
      therapies: therapies,
      referenceDate: referenceDate,
      period: AdherenceTrendPeriod.last7Days,
      therapyId: 'therapy-a',
    );

    expect(trend.last.evaluatedRecords, 1);
    expect(trend.last.adherencePercent, 100);
  });

  test('builds all trend from the first record to the reference date', () {
    final trend = HistoryStatisticsService.adherenceTrend(
      records: [
        _record(
          id: 'old',
          medicineId: 'medicine-a',
          medicineName: 'Tachis',
          scheduledDateTime: DateTime(2026, 7, 1, 8),
          status: IntakeStatus.taken,
        ),
      ],
      therapies: therapies,
      referenceDate: referenceDate,
      period: AdherenceTrendPeriod.all,
    );

    expect(trend.first.date, DateTime(2026, 7, 1));
    expect(trend.last.date, DateTime(2026, 7, 6));
    expect(trend, hasLength(6));
  });
}

Therapy _therapy({
  required String id,
  required String name,
  required List<Medicine> medicines,
  bool isActive = true,
}) {
  return Therapy(
    id: id,
    name: name,
    color: '#2E7D32',
    medicines: medicines,
    isActive: isActive,
  );
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
