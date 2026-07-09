import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/intake_record.dart';
import '../models/medicine.dart';
import '../models/therapy.dart';

class TherapyPdfStatistics {
  final int evaluatedRecords;
  final int taken;
  final int skipped;
  final int missed;

  const TherapyPdfStatistics({
    required this.evaluatedRecords,
    required this.taken,
    required this.skipped,
    required this.missed,
  });

  int get adherencePercent =>
      evaluatedRecords == 0 ? 0 : ((taken / evaluatedRecords) * 100).round();
}

class TherapyPdfExportService {
  const TherapyPdfExportService._();

  static Future<Uint8List> generateTherapySummary({
    required Therapy therapy,
    required Iterable<Medicine> medicines,
    required Iterable<IntakeRecord> intakeRecords,
    DateTime? referenceDate,
  }) async {
    final now = referenceDate ?? DateTime.now();
    final medicineList = medicines.toList(growable: false);
    final relevantRecords = recordsForTherapyLast30Days(
      medicines: medicineList,
      records: intakeRecords,
      referenceDate: now,
    );
    final statistics = calculateStatistics(relevantRecords);
    final document = pw.Document(
      title: 'Riepilogo terapia - ${therapy.name}',
      author: 'Meditrack',
      creator: 'Meditrack',
    );

    document.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(),
        ),
        build: (context) => [
          _header(therapy, now),
          pw.SizedBox(height: 18),
          _sectionTitle('Informazioni terapia'),
          _therapyInfo(therapy),
          pw.SizedBox(height: 18),
          _sectionTitle('Medicine associate'),
          if (medicineList.isEmpty)
            _emptyBox('Nessuna medicina associata a questa terapia.')
          else
            ...medicineList.map(_medicineCard),
          pw.SizedBox(height: 18),
          _sectionTitle('Riepilogo aderenza'),
          _adherenceSummary(statistics),
          pw.SizedBox(height: 8),
          pw.Text(
            'Periodo storico usato: ultimi 30 giorni, inclusa la giornata corrente.',
            style: _bodyStyle(color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 18),
          _disclaimer(),
        ],
      ),
    );

    return document.save();
  }

  static List<IntakeRecord> recordsForTherapyLast30Days({
    required Iterable<Medicine> medicines,
    required Iterable<IntakeRecord> records,
    required DateTime referenceDate,
  }) {
    final medicineIds = medicines.map((medicine) => medicine.id).toSet();
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final start = today.subtract(const Duration(days: 29));
    final end = today.add(const Duration(days: 1));

    return records
        .where(
          (record) =>
              record.medicineId != null &&
              medicineIds.contains(record.medicineId) &&
              !record.scheduledDateTime.isBefore(start) &&
              record.scheduledDateTime.isBefore(end),
        )
        .toList(growable: false)
      ..sort(
        (first, second) =>
            first.scheduledDateTime.compareTo(second.scheduledDateTime),
      );
  }

  static TherapyPdfStatistics calculateStatistics(
    Iterable<IntakeRecord> records,
  ) {
    var taken = 0;
    var skipped = 0;
    var missed = 0;

    for (final record in records) {
      switch (record.status) {
        case IntakeStatus.taken:
          taken++;
        case IntakeStatus.skipped:
          skipped++;
        case IntakeStatus.missed:
          missed++;
        case IntakeStatus.scheduled:
          break;
      }
    }

    return TherapyPdfStatistics(
      evaluatedRecords: taken + skipped + missed,
      taken: taken,
      skipped: skipped,
      missed: missed,
    );
  }

  static String buildFileName({
    required String therapyName,
    required DateTime date,
  }) {
    final sanitized = sanitizeFileName(therapyName);
    return 'meditrack_terapia_${sanitized}_${_formatFileDate(date)}.pdf';
  }

  static String sanitizeFileName(String value) {
    final cleaned = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
    return cleaned.isEmpty ? 'terapia' : cleaned;
  }

  static pw.Widget _header(Therapy therapy, DateTime generatedAt) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(18),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.green800, width: 1),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Riepilogo terapia',
            style: pw.TextStyle(
              color: PdfColors.green900,
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            therapy.name,
            style: pw.TextStyle(
              color: PdfColors.grey900,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generato il ${_formatDate(generatedAt)} alle ${_formatTime(generatedAt)}',
            style: _bodyStyle(color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          color: PdfColors.green900,
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
        ),
      ),
    );
  }

  static pw.Widget _therapyInfo(Therapy therapy) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _infoRow('Nome terapia', therapy.name),
          _infoRow('Stato', therapy.isActive ? 'Attiva' : 'Archiviata'),
          if (therapy.startDate != null)
            _infoRow('Data inizio', _formatDate(therapy.startDate!)),
          if (therapy.description?.trim().isNotEmpty ?? false)
            _infoRow('Note', therapy.description!.trim()),
        ],
      ),
    );
  }

  static pw.Widget _medicineCard(Medicine medicine) {
    return pw.Container(
      width: double.infinity,
      margin: const pw.EdgeInsets.only(bottom: 10),
      padding: const pw.EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Text(
                  medicine.name,
                  style: pw.TextStyle(
                    color: PdfColors.grey900,
                    fontSize: 13,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Text(
                medicine.isActive ? 'Attiva' : 'Inattiva',
                style: _bodyStyle(
                  color: medicine.isActive
                      ? PdfColors.green800
                      : PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 6),
          _infoRow('Dose', medicine.doseLabel),
          _infoRow('Programmazione', _scheduleLabel(medicine)),
          _infoRow(
            'Scorta attuale',
            Medicine.formatQuantity(medicine.stockQuantity),
          ),
          _infoRow(
            'Soglia minima',
            Medicine.formatQuantity(medicine.stockWarningThreshold),
          ),
          if (medicine.notes?.trim().isNotEmpty ?? false)
            _infoRow('Note', medicine.notes!.trim()),
        ],
      ),
    );
  }

  static pw.Widget _adherenceSummary(TherapyPdfStatistics statistics) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _infoRow('Assunzioni valutate', '${statistics.evaluatedRecords}'),
          _infoRow('Assunte', '${statistics.taken}'),
          _infoRow('Saltate', '${statistics.skipped}'),
          _infoRow('Dimenticate', '${statistics.missed}'),
          _infoRow(
            'Aderenza',
            statistics.evaluatedRecords == 0
                ? 'Nessun dato valutabile'
                : '${statistics.adherencePercent}%',
          ),
        ],
      ),
    );
  }

  static pw.Widget _disclaimer() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text(
        "Questo documento e' un riepilogo personale e non sostituisce indicazioni mediche professionali.",
        style: _bodyStyle(color: PdfColors.grey700),
      ),
    );
  }

  static pw.Widget _emptyBox(String text) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: _boxDecoration(),
      child: pw.Text(text, style: _bodyStyle(color: PdfColors.grey700)),
    );
  }

  static pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 110,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                color: PdfColors.grey700,
                fontSize: 9,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value.trim().isEmpty ? 'Non disponibile' : value.trim(),
              style: _bodyStyle(color: PdfColors.grey900),
            ),
          ),
        ],
      ),
    );
  }

  static pw.BoxDecoration _boxDecoration() {
    return pw.BoxDecoration(
      color: PdfColors.white,
      borderRadius: pw.BorderRadius.circular(8),
      border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
    );
  }

  static pw.TextStyle _bodyStyle({required PdfColor color}) {
    return pw.TextStyle(color: color, fontSize: 10);
  }

  static String _scheduleLabel(Medicine medicine) {
    final activeSchedules = medicine.schedules
        .where((schedule) => schedule.isActive)
        .toList(growable: false);
    if (activeSchedules.isEmpty) return 'Non programmata';

    return activeSchedules
        .map((schedule) {
          final days = schedule.daysOfWeek
              .map(_dayLabel)
              .where((day) => day.isNotEmpty)
              .join(', ');
          final time = _formatScheduleTime(
            schedule.time.hour,
            schedule.time.minute,
          );
          return '${days.isEmpty ? 'Giorni non definiti' : days} - $time';
        })
        .join('; ');
  }

  static String _dayLabel(int day) {
    return switch (day) {
      DateTime.monday => 'Lun',
      DateTime.tuesday => 'Mar',
      DateTime.wednesday => 'Mer',
      DateTime.thursday => 'Gio',
      DateTime.friday => 'Ven',
      DateTime.saturday => 'Sab',
      DateTime.sunday => 'Dom',
      _ => '',
    };
  }

  static String _formatScheduleTime(int hour, int minute) {
    final paddedHour = hour.toString().padLeft(2, '0');
    final paddedMinute = minute.toString().padLeft(2, '0');
    return '$paddedHour:$paddedMinute';
  }

  static String _formatDate(DateTime value) {
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    return '$day/$month/${value.year}';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatFileDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
