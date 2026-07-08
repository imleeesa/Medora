import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/intake_record.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/models/therapy.dart';
import 'package:meditrack/services/csv_export_service.dart';
import 'package:meditrack/services/history_filter_service.dart';

void main() {
  final therapies = [
    _therapy(
      id: 'therapy-a',
      name: 'Terapia, principale',
      medicines: [
        _medicine(id: 'medicine-a', name: 'Medicina A', therapyId: 'therapy-a'),
      ],
    ),
    _therapy(
      id: 'therapy-b',
      name: 'Terapia B',
      medicines: [
        _medicine(id: 'medicine-b', name: 'Medicina B', therapyId: 'therapy-b'),
      ],
    ),
  ];

  test('exports headers for an empty intake history', () {
    final csv = CsvExportService.exportIntakeHistory(
      records: const [],
      therapies: therapies,
    );

    expect(
      csv,
      'scheduled_date,scheduled_time,medicine_name,therapy_name,dose,status,recorded_at,notes',
    );
  });

  test('exports taken, skipped and missed states with readable labels', () {
    final csv = CsvExportService.exportIntakeHistory(
      records: [
        _record(id: 'taken', status: IntakeStatus.taken),
        _record(id: 'skipped', status: IntakeStatus.skipped),
        _record(id: 'missed', status: IntakeStatus.missed),
      ],
      therapies: therapies,
    );

    expect(csv, contains('Assunta'));
    expect(csv, contains('Saltata'));
    expect(csv, contains('Dimenticata'));
  });

  test('exports scheduled records as programmed', () {
    final csv = CsvExportService.exportIntakeHistory(
      records: [_record(id: 'scheduled', status: IntakeStatus.scheduled)],
      therapies: therapies,
    );

    expect(csv, contains('Programmata'));
  });

  test('escapes commas, quotes and new lines', () {
    final csv = CsvExportService.exportIntakeHistory(
      records: [
        _record(
          id: 'special',
          medicineName: 'Medicina, "speciale"',
          dose: '1 compressa',
          notes: 'Prima riga\nSeconda riga',
          status: IntakeStatus.taken,
        ),
      ],
      therapies: therapies,
    );

    expect(csv, contains('"Medicina, ""speciale"""'));
    expect(csv, contains('"Terapia, principale"'));
    expect(csv, contains('"Prima riga\nSeconda riga"'));
  });

  test('keeps apostrophes and long names readable', () {
    const longName =
        'Medicina con nome molto lungo per verificare esportazione completa';
    final csv = CsvExportService.exportIntakeHistory(
      records: [
        _record(
          id: 'long',
          medicineName: "$longName dell'utente",
          notes: "Nota dell'utente",
          status: IntakeStatus.taken,
        ),
      ],
      therapies: therapies,
    );

    expect(csv, contains("$longName dell'utente"));
    expect(csv, contains("Nota dell'utente"));
  });

  test('exports deleted medicines through snapshot name', () {
    final csv = CsvExportService.exportIntakeHistory(
      records: [
        _record(
          id: 'deleted',
          medicineId: null,
          medicineName: 'Medicina eliminata',
          status: IntakeStatus.missed,
        ),
      ],
      therapies: therapies,
    );

    expect(csv, contains('Medicina eliminata'));
    expect(csv, contains('Non disponibile'));
  });

  test('uses safe fallback when medicine and snapshot are missing', () {
    final csv = CsvExportService.exportIntakeHistory(
      records: [
        _record(
          id: 'missing',
          medicineId: 'unknown-medicine',
          medicineName: '',
          status: IntakeStatus.skipped,
        ),
      ],
      therapies: therapies,
    );

    expect(csv, contains('Medicina non disponibile'));
    expect(csv, contains('Non disponibile'));
  });

  test('preserves the incoming order used by visible filtered records', () {
    final csv = CsvExportService.exportIntakeHistory(
      records: [
        _record(
          id: 'newer',
          scheduledDateTime: DateTime(2026, 7, 8, 9),
          medicineName: 'Nuova',
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'older',
          scheduledDateTime: DateTime(2026, 7, 7, 9),
          medicineName: 'Vecchia',
          status: IntakeStatus.taken,
        ),
      ],
      therapies: therapies,
    );
    final lines = csv.split('\n');

    expect(lines[1], contains('Nuova'));
    expect(lines[2], contains('Vecchia'));
  });

  test('exports only records visible after a status filter', () {
    final filtered = HistoryFilterService.filterRecords(
      records: [
        _record(id: 'taken', status: IntakeStatus.taken),
        _record(id: 'skipped', status: IntakeStatus.skipped),
        _record(id: 'missed', status: IntakeStatus.missed),
      ],
      therapies: therapies,
      filters: const HistoryFilters(status: HistoryStatusFilter.taken),
      referenceDate: DateTime(2026, 7, 8, 12),
    );
    final csv = CsvExportService.exportIntakeHistory(
      records: filtered,
      therapies: therapies,
    );

    expect(csv, contains('Assunta'));
    expect(csv, isNot(contains('Saltata')));
    expect(csv, isNot(contains('Dimenticata')));
  });

  test('exports only records visible after combined filters', () {
    final filtered = HistoryFilterService.filterRecords(
      records: [
        _record(
          id: 'matching',
          medicineId: 'medicine-a',
          medicineName: 'Medicina A',
          scheduledDateTime: DateTime(2026, 7, 8, 8),
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'wrong-medicine',
          medicineId: 'medicine-b',
          medicineName: 'Medicina B',
          scheduledDateTime: DateTime(2026, 7, 8, 8),
          status: IntakeStatus.taken,
        ),
        _record(
          id: 'wrong-period',
          medicineId: 'medicine-a',
          medicineName: 'Medicina A vecchia',
          scheduledDateTime: DateTime(2026, 6, 1, 8),
          status: IntakeStatus.taken,
        ),
      ],
      therapies: therapies,
      filters: const HistoryFilters(
        status: HistoryStatusFilter.taken,
        period: HistoryPeriodFilter.last7Days,
        therapyId: 'therapy-a',
        medicineId: 'medicine-a',
      ),
      referenceDate: DateTime(2026, 7, 8, 12),
    );
    final csv = CsvExportService.exportIntakeHistory(
      records: filtered,
      therapies: therapies,
    );

    expect(filtered, hasLength(1));
    expect(csv, contains('Medicina A'));
    expect(csv, isNot(contains('Medicina B')));
    expect(csv, isNot(contains('Medicina A vecchia')));
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
  String? medicineId = 'medicine-a',
  String medicineName = 'Medicina A',
  String dose = '1 compressa',
  DateTime? scheduledDateTime,
  IntakeStatus status = IntakeStatus.taken,
  String? notes,
}) {
  final scheduled = scheduledDateTime ?? DateTime(2026, 7, 8, 8);
  return IntakeRecord(
    id: id,
    medicineId: medicineId,
    profileId: 'profile-1',
    scheduledDateTime: scheduled,
    actualDateTime: status == IntakeStatus.taken
        ? scheduled.add(const Duration(minutes: 5))
        : null,
    status: status,
    notes: notes,
    medicineNameSnapshot: medicineName,
    medicineDoseSnapshot: dose,
  );
}
