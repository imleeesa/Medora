import 'medicine.dart';
import 'intake_record.dart';

/// Una singola assunzione programmata per la giornata corrente.
class ScheduledIntake {
  final Medicine medicine;
  final DateTime scheduledDateTime;
  final IntakeRecord? record;

  const ScheduledIntake({
    required this.medicine,
    required this.scheduledDateTime,
    this.record,
  });

  IntakeStatus get status => record?.status ?? IntakeStatus.scheduled;
}
