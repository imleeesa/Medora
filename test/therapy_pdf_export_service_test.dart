import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/intake_record.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/models/medicine_schedule.dart';
import 'package:meditrack/models/therapy.dart';
import 'package:meditrack/services/therapy_pdf_export_service.dart';

void main() {
  test('generates a PDF for a therapy with medicines', () async {
    final bytes = await TherapyPdfExportService.generateTherapySummary(
      therapy: _therapy(medicines: [_medicine()]),
      medicines: [_medicine()],
      intakeRecords: [
        _record(id: 'taken', status: IntakeStatus.taken),
        _record(id: 'skipped', status: IntakeStatus.skipped),
      ],
      referenceDate: DateTime(2026, 7, 9, 12),
    );

    expect(bytes.length, greaterThan(500));
    expect(utf8.decode(bytes.take(4).toList()), '%PDF');
  });

  test('generates a PDF for a therapy without medicines or history', () async {
    final bytes = await TherapyPdfExportService.generateTherapySummary(
      therapy: _therapy(medicines: const []),
      medicines: const [],
      intakeRecords: const [],
      referenceDate: DateTime(2026, 7, 9, 12),
    );

    expect(bytes.length, greaterThan(500));
    expect(utf8.decode(bytes.take(4).toList()), '%PDF');
  });

  test('filters therapy records to current medicines in the last 30 days', () {
    final medicine = _medicine();
    final records = TherapyPdfExportService.recordsForTherapyLast30Days(
      medicines: [medicine],
      records: [
        _record(id: 'inside', scheduledDateTime: DateTime(2026, 7, 1, 8)),
        _record(id: 'old', scheduledDateTime: DateTime(2026, 5, 1, 8)),
        _record(
          id: 'other',
          medicineId: 'other-medicine',
          scheduledDateTime: DateTime(2026, 7, 1, 8),
        ),
        _record(
          id: 'deleted',
          medicineId: null,
          scheduledDateTime: DateTime(2026, 7, 1, 8),
        ),
      ],
      referenceDate: DateTime(2026, 7, 9, 12),
    );

    expect(records.map((record) => record.id), ['inside']);
  });

  test('calculates adherence statistics excluding scheduled records', () {
    final statistics = TherapyPdfExportService.calculateStatistics([
      _record(id: 'taken', status: IntakeStatus.taken),
      _record(id: 'skipped', status: IntakeStatus.skipped),
      _record(id: 'missed', status: IntakeStatus.missed),
      _record(id: 'scheduled', status: IntakeStatus.scheduled),
    ]);

    expect(statistics.evaluatedRecords, 3);
    expect(statistics.taken, 1);
    expect(statistics.skipped, 1);
    expect(statistics.missed, 1);
    expect(statistics.adherencePercent, 33);
  });

  test('supports advanced schedules while generating PDF bytes', () async {
    final medicine = _medicine(
      schedules: const [
        MedicineSchedule(
          time: TimeOfDay(hour: 15, minute: 30),
          daysOfWeek: [DateTime.monday, DateTime.saturday],
        ),
        MedicineSchedule(
          time: TimeOfDay(hour: 16, minute: 35),
          daysOfWeek: [DateTime.tuesday, DateTime.sunday],
        ),
      ],
    );

    final bytes = await TherapyPdfExportService.generateTherapySummary(
      therapy: _therapy(medicines: [medicine]),
      medicines: [medicine],
      intakeRecords: const [],
      referenceDate: DateTime(2026, 7, 9, 12),
    );

    expect(bytes.length, greaterThan(500));
    expect(utf8.decode(bytes.take(4).toList()), '%PDF');
  });

  test('sanitizes PDF file names with fallback', () {
    expect(
      TherapyPdfExportService.buildFileName(
        therapyName: 'Terapia, "Speciale" 2026',
        date: DateTime(2026, 7, 9),
      ),
      'meditrack_terapia_terapia_speciale_2026_2026-07-09.pdf',
    );
    expect(
      TherapyPdfExportService.buildFileName(
        therapyName: '   ',
        date: DateTime(2026, 7, 9),
      ),
      'meditrack_terapia_terapia_2026-07-09.pdf',
    );
  });
}

Therapy _therapy({required List<Medicine> medicines}) {
  return Therapy(
    id: 'therapy-a',
    name: 'Antibiotico',
    description: 'Dopo visita medica',
    color: '#2E7D32',
    startDate: DateTime(2026, 7, 1),
    medicines: medicines,
  );
}

Medicine _medicine({List<MedicineSchedule>? schedules}) {
  final now = DateTime(2026, 7, 1);
  final resolvedSchedules =
      schedules ??
      const [
        MedicineSchedule(
          time: TimeOfDay(hour: 8, minute: 0),
          daysOfWeek: [DateTime.monday, DateTime.wednesday, DateTime.friday],
        ),
        MedicineSchedule(
          time: TimeOfDay(hour: 20, minute: 0),
          daysOfWeek: [DateTime.monday, DateTime.wednesday, DateTime.friday],
        ),
      ];
  return Medicine(
    id: 'medicine-a',
    name: 'Augmentin',
    therapyId: 'therapy-a',
    dose: '1 compressa',
    notes: 'Dopo i pasti',
    times: resolvedSchedules.map((schedule) => schedule.time).toList(),
    daysOfWeek: resolvedSchedules
        .expand((schedule) => schedule.daysOfWeek)
        .toSet()
        .toList(),
    schedules: resolvedSchedules,
    stockQuantity: 10.5,
    stockWarningThreshold: 2,
    createdAt: now,
    updatedAt: now,
  );
}

IntakeRecord _record({
  required String id,
  String? medicineId = 'medicine-a',
  DateTime? scheduledDateTime,
  IntakeStatus status = IntakeStatus.taken,
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
    medicineNameSnapshot: 'Augmentin',
    medicineDoseSnapshot: '1 compressa',
  );
}
