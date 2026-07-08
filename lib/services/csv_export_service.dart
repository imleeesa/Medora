import '../models/intake_record.dart';
import '../models/medicine.dart';
import '../models/therapy.dart';

class CsvExportService {
  const CsvExportService._();

  static const historyHeaders = [
    'scheduled_date',
    'scheduled_time',
    'medicine_name',
    'therapy_name',
    'dose',
    'status',
    'recorded_at',
    'notes',
  ];

  static String exportIntakeHistory({
    required Iterable<IntakeRecord> records,
    required Iterable<Therapy> therapies,
  }) {
    final medicineById = _medicineById(therapies);
    final therapyById = {for (final therapy in therapies) therapy.id: therapy};
    final rows = <List<String>>[
      historyHeaders,
      for (final record in records)
        _historyRow(
          record: record,
          medicineById: medicineById,
          therapyById: therapyById,
        ),
    ];

    return rows.map(_csvRow).join('\n');
  }

  static List<String> _historyRow({
    required IntakeRecord record,
    required Map<String, Medicine> medicineById,
    required Map<String, Therapy> therapyById,
  }) {
    final scheduled = record.scheduledDateTime;
    final medicine = record.medicineId == null
        ? null
        : medicineById[record.medicineId];
    final therapyId = medicine?.therapyId;
    final therapy = therapyId == null ? null : therapyById[therapyId];

    return [
      _formatDate(scheduled),
      _formatTime(scheduled),
      _medicineName(record, medicine),
      therapy?.name ?? 'Non disponibile',
      record.doseLabel,
      _statusLabel(record.status),
      record.actualDateTime == null
          ? ''
          : _formatDateTime(record.actualDateTime!),
      record.notes?.trim() ?? '',
    ];
  }

  static String _csvRow(List<String> values) {
    return values.map(_escape).join(',');
  }

  static String _escape(String value) {
    final needsQuotes =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    final escaped = value.replaceAll('"', '""');
    return needsQuotes ? '"$escaped"' : escaped;
  }

  static Map<String, Medicine> _medicineById(Iterable<Therapy> therapies) {
    return {
      for (final therapy in therapies)
        for (final medicine in therapy.medicines) medicine.id: medicine,
    };
  }

  static String _medicineName(IntakeRecord record, Medicine? medicine) {
    final snapshot = record.medicineNameSnapshot.trim();
    if (snapshot.isNotEmpty) return snapshot;
    return medicine?.name ?? 'Medicina non disponibile';
  }

  static String _statusLabel(IntakeStatus status) {
    return switch (status) {
      IntakeStatus.taken => 'Assunta',
      IntakeStatus.skipped => 'Saltata',
      IntakeStatus.missed => 'Dimenticata',
      IntakeStatus.scheduled => 'Programmata',
    };
  }

  static String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String _formatTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatDateTime(DateTime value) {
    return '${_formatDate(value)} ${_formatTime(value)}';
  }
}
