import '../models/intake_record.dart';
import '../models/medicine.dart';
import '../models/therapy.dart';

class MissedIntakeCandidate {
  final Medicine medicine;
  final DateTime scheduledDateTime;

  const MissedIntakeCandidate({
    required this.medicine,
    required this.scheduledDateTime,
  });
}

/// Individua gli slot passati senza un record nello storico.
class MissedIntakePlanner {
  static const defaultLookbackDays = 7;

  const MissedIntakePlanner._();

  static List<MissedIntakeCandidate> findCandidates({
    required Iterable<Therapy> therapies,
    required Iterable<IntakeRecord> records,
    required DateTime referenceDate,
    int lookbackDays = defaultLookbackDays,
  }) {
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final recordedSlots = <String>{
      for (final record in records)
        if (record.medicineId != null)
          _slotKey(record.medicineId!, record.scheduledDateTime),
    };
    final candidates = <MissedIntakeCandidate>[];

    for (var offset = 1; offset <= lookbackDays; offset++) {
      final date = today.subtract(Duration(days: offset));
      for (final therapy in therapies.where((therapy) => therapy.isActive)) {
        for (final medicine in therapy.medicines.where(
          (medicine) => medicine.isActive,
        )) {
          for (final schedule in medicine.schedules) {
            if (!schedule.isActive ||
                !schedule.daysOfWeek.contains(date.weekday)) {
              continue;
            }
            final scheduledDateTime = DateTime(
              date.year,
              date.month,
              date.day,
              schedule.time.hour,
              schedule.time.minute,
            );
            if (!_isEligibleSlot(
              therapy: therapy,
              medicine: medicine,
              scheduleCreatedAt: schedule.createdAt,
              scheduledDateTime: scheduledDateTime,
            )) {
              continue;
            }
            final key = _slotKey(medicine.id, scheduledDateTime);
            if (recordedSlots.add(key)) {
              candidates.add(
                MissedIntakeCandidate(
                  medicine: medicine,
                  scheduledDateTime: scheduledDateTime,
                ),
              );
            }
          }
        }
      }
    }

    candidates.sort(
      (first, second) =>
          first.scheduledDateTime.compareTo(second.scheduledDateTime),
    );
    return candidates;
  }

  static String _slotKey(String medicineId, DateTime scheduledDateTime) =>
      '$medicineId|${scheduledDateTime.toIso8601String()}';

  /// Uno slot storico e' valido solo dal momento in cui terapia, medicina e
  /// relativo schedule esistono effettivamente.
  static bool _isEligibleSlot({
    required Therapy therapy,
    required Medicine medicine,
    required DateTime? scheduleCreatedAt,
    required DateTime scheduledDateTime,
  }) {
    var firstEligibleDateTime = medicine.createdAt;

    final therapyStartDate = therapy.startDate;
    if (therapyStartDate != null &&
        therapyStartDate.isAfter(firstEligibleDateTime)) {
      firstEligibleDateTime = therapyStartDate;
    }

    if (scheduleCreatedAt != null &&
        scheduleCreatedAt.isAfter(firstEligibleDateTime)) {
      firstEligibleDateTime = scheduleCreatedAt;
    }

    return !scheduledDateTime.isBefore(firstEligibleDateTime);
  }
}
