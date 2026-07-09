import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/intake_record.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/models/medicine_schedule.dart';
import 'package:meditrack/models/therapy.dart';
import 'package:meditrack/services/therapy_pdf_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('plain text summary contains core therapy and medicine content', () {
    final medicine = _medicine();
    final summary = TherapyPdfExportService.buildPlainTextSummary(
      therapy: _therapy(medicines: [medicine]),
      medicines: [medicine],
      intakeRecords: [_record(id: 'taken', status: IntakeStatus.taken)],
      referenceDate: DateTime(2026, 7, 9, 12),
    );

    expect(summary, contains('Riepilogo terapia'));
    expect(summary, contains('Antibiotico'));
    expect(summary, contains('Attiva'));
    expect(summary, contains('Dopo visita medica'));
    expect(summary, contains('Augmentin'));
    expect(summary, contains('1 compressa'));
    expect(summary, contains('Lun, Mer, Ven - 08:00'));
    expect(summary, contains('10.5'));
    expect(summary, contains('2'));
    expect(summary, contains('100%'));
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

    final summary = TherapyPdfExportService.buildPlainTextSummary(
      therapy: _therapy(medicines: const []),
      medicines: const [],
      intakeRecords: const [],
      referenceDate: DateTime(2026, 7, 9, 12),
    );

    expect(summary, contains('Nessuna medicina associata'));
    expect(summary, contains('Nessun dato valutabile'));
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

  test('keeps common Italian accents and symbols with bundled fonts', () async {
    final therapy = _therapy(
      name: 'Terapia qualità: è già più stabile',
      description: 'Note con à, è, é, ì, ò, ù, apostrofi e virgolette "ok".',
      medicines: [
        _medicine(
          name: 'Medicìna μ-speciale ½',
          dose: '½ compressa a 37°',
          notes:
              'Prendere dopo caffè. Nota lunga: ${'test '.padRight(140, 'x')}',
        ),
      ],
    );

    final bytes = await TherapyPdfExportService.generateTherapySummary(
      therapy: therapy,
      medicines: therapy.medicines,
      intakeRecords: const [],
      referenceDate: DateTime(2026, 7, 9, 12),
    );
    final summary = TherapyPdfExportService.buildPlainTextSummary(
      therapy: therapy,
      medicines: therapy.medicines,
      intakeRecords: const [],
      referenceDate: DateTime(2026, 7, 9, 12),
    );

    expect(bytes.length, greaterThan(500));
    expect(summary, contains('qualità'));
    expect(summary, contains('è già più stabile'));
    expect(summary, contains('à, è, é, ì, ò, ù'));
    expect(summary, contains('Medicìna μ-speciale ½'));
    expect(summary, contains('½ compressa a 37°'));
  });

  test(
    'represents archived therapy, inactive medicine and empty dose safely',
    () {
      final medicine = _medicine(dose: '', isActive: false);
      final summary = TherapyPdfExportService.buildPlainTextSummary(
        therapy: _therapy(isActive: false, medicines: [medicine]),
        medicines: [medicine],
        intakeRecords: const [],
        referenceDate: DateTime(2026, 7, 9, 12),
      );

      expect(summary, contains('Archiviata'));
      expect(summary, contains('Inattiva'));
      expect(summary, contains('Dose non specificata'));
    },
  );

  test('sanitizes PDF file names with fallback and length cap', () {
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
    expect(
      TherapyPdfExportService.buildFileName(
        therapyName:
            'Terapia con nome lunghissimo da non lasciare crescere senza limite',
        date: DateTime(2026, 7, 9),
      ),
      'meditrack_terapia_terapia_con_nome_lunghissimo_da_non_lasciare_2026-07-09.pdf',
    );
  });

  test('removes emoji surrogate pairs from PDF text', () {
    expect(
      TherapyPdfExportService.sanitizePdfText('Nota terapia 🩺 importante'),
      'Nota terapia  importante',
    );
  });
}

Therapy _therapy({
  String name = 'Antibiotico',
  String? description = 'Dopo visita medica',
  bool isActive = true,
  required List<Medicine> medicines,
}) {
  return Therapy(
    id: 'therapy-a',
    name: name,
    description: description,
    color: '#2E7D32',
    isActive: isActive,
    startDate: DateTime(2026, 7, 1),
    medicines: medicines,
  );
}

Medicine _medicine({
  String name = 'Augmentin',
  String dose = '1 compressa',
  String? notes = 'Dopo i pasti',
  bool isActive = true,
  List<MedicineSchedule>? schedules,
}) {
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
    name: name,
    therapyId: 'therapy-a',
    dose: dose,
    notes: notes,
    times: resolvedSchedules.map((schedule) => schedule.time).toList(),
    daysOfWeek: resolvedSchedules
        .expand((schedule) => schedule.daysOfWeek)
        .toSet()
        .toList(),
    schedules: resolvedSchedules,
    stockQuantity: 10.5,
    stockWarningThreshold: 2,
    isActive: isActive,
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
