import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/intake_record.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/models/therapy.dart';
import 'package:meditrack/services/history_filter_service.dart';

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
  final records = [
    _record(
      id: 'taken-today',
      medicineId: 'medicine-a',
      medicineName: 'Tachis',
      scheduledDateTime: DateTime(2026, 7, 6, 8),
      status: IntakeStatus.taken,
    ),
    _record(
      id: 'skipped-yesterday',
      medicineId: 'medicine-a',
      medicineName: 'Tachis',
      scheduledDateTime: DateTime(2026, 7, 5, 20),
      status: IntakeStatus.skipped,
    ),
    _record(
      id: 'missed-eight-days',
      medicineId: 'medicine-b',
      medicineName: 'Vitamina D',
      scheduledDateTime: DateTime(2026, 6, 28, 9),
      status: IntakeStatus.missed,
    ),
    _record(
      id: 'taken-twenty-days',
      medicineId: 'medicine-b',
      medicineName: 'Vitamina D',
      scheduledDateTime: DateTime(2026, 6, 16, 9),
      status: IntakeStatus.taken,
    ),
    _record(
      id: 'deleted-medicine',
      medicineId: null,
      medicineName: 'Medicina eliminata',
      scheduledDateTime: DateTime(2026, 7, 6, 10),
      status: IntakeStatus.taken,
    ),
    _record(
      id: 'old-skipped',
      medicineId: 'medicine-a',
      medicineName: 'Tachis',
      scheduledDateTime: DateTime(2026, 5, 20, 8),
      status: IntakeStatus.skipped,
    ),
  ];

  List<String> ids({
    HistoryStatusFilter status = HistoryStatusFilter.all,
    HistoryPeriodFilter period = HistoryPeriodFilter.all,
    String? therapyId,
    String? medicineId,
    String? medicineSnapshotName,
  }) {
    return HistoryFilterService.filterRecords(
      records: records,
      therapies: therapies,
      filters: HistoryFilters(
        status: status,
        period: period,
        therapyId: therapyId,
        medicineId: medicineId,
        medicineSnapshotName: medicineSnapshotName,
      ),
      referenceDate: referenceDate,
    ).map((record) => record.id).toList(growable: false);
  }

  test('filters taken, skipped and missed records by status', () {
    expect(ids(status: HistoryStatusFilter.taken), [
      'deleted-medicine',
      'taken-today',
      'taken-twenty-days',
    ]);
    expect(ids(status: HistoryStatusFilter.skipped), [
      'skipped-yesterday',
      'old-skipped',
    ]);
    expect(ids(status: HistoryStatusFilter.missed), ['missed-eight-days']);
  });

  test('filters by today, last 7 days and last 30 days', () {
    expect(ids(period: HistoryPeriodFilter.today), [
      'deleted-medicine',
      'taken-today',
    ]);
    expect(ids(period: HistoryPeriodFilter.last7Days), [
      'deleted-medicine',
      'taken-today',
      'skipped-yesterday',
    ]);
    expect(ids(period: HistoryPeriodFilter.last30Days), [
      'deleted-medicine',
      'taken-today',
      'skipped-yesterday',
      'missed-eight-days',
      'taken-twenty-days',
    ]);
  });

  test('filters by therapy and medicine', () {
    expect(ids(therapyId: 'therapy-a'), [
      'taken-today',
      'skipped-yesterday',
      'old-skipped',
    ]);
    expect(ids(medicineId: 'medicine-b'), [
      'missed-eight-days',
      'taken-twenty-days',
    ]);
  });

  test('combines status with period and therapy with medicine', () {
    expect(
      ids(
        status: HistoryStatusFilter.taken,
        period: HistoryPeriodFilter.last7Days,
      ),
      ['deleted-medicine', 'taken-today'],
    );
    expect(ids(therapyId: 'therapy-b', medicineId: 'medicine-b'), [
      'missed-eight-days',
      'taken-twenty-days',
    ]);
  });

  test('keeps deleted medicine records filterable through snapshots', () {
    final options = HistoryFilterService.buildMedicineOptions(
      records: records,
      therapies: therapies,
    );

    expect(
      options.map((option) => option.label),
      contains('Medicina eliminata (eliminata)'),
    );
    expect(ids(medicineSnapshotName: 'Medicina eliminata'), [
      'deleted-medicine',
    ]);
  });

  test('returns empty when no record matches the combined filters', () {
    expect(
      ids(
        status: HistoryStatusFilter.missed,
        period: HistoryPeriodFilter.today,
        therapyId: 'therapy-a',
      ),
      isEmpty,
    );
  });
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
