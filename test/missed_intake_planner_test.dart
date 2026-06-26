import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/intake_record.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/models/medicine_schedule.dart';
import 'package:meditrack/models/therapy.dart';
import 'package:meditrack/services/missed_intake_planner.dart';

void main() {
  final referenceDate = DateTime(2026, 6, 24, 12);
  final yesterday = referenceDate.subtract(const Duration(days: 1));

  test('creates a candidate for an unrecorded past intake', () {
    final medicine = _medicine(daysOfWeek: [yesterday.weekday]);
    final candidates = MissedIntakePlanner.findCandidates(
      therapies: [_therapy(medicine)],
      records: const [],
      referenceDate: referenceDate,
      lookbackDays: 1,
    );

    expect(candidates, hasLength(1));
    expect(candidates.single.scheduledDateTime, DateTime(2026, 6, 23, 8));
    expect(medicine.stockQuantity, 10.0);
  });

  test('does not create missed records before a medicine was created', () {
    final medicine = _medicine(
      daysOfWeek: [yesterday.weekday],
      createdAt: referenceDate,
    );

    final candidates = MissedIntakePlanner.findCandidates(
      therapies: [_therapy(medicine)],
      records: const [],
      referenceDate: referenceDate,
      lookbackDays: 1,
    );

    expect(candidates, isEmpty);
  });

  test('does not create missed records before a schedule was created', () {
    final medicine = _medicine(
      daysOfWeek: [yesterday.weekday],
      scheduleCreatedAt: referenceDate,
    );

    final candidates = MissedIntakePlanner.findCandidates(
      therapies: [_therapy(medicine)],
      records: const [],
      referenceDate: referenceDate,
      lookbackDays: 1,
    );

    expect(candidates, isEmpty);
  });

  test(
    'does not duplicate or replace records already saved for a past slot',
    () {
      final medicine = _medicine(daysOfWeek: [yesterday.weekday]);
      final scheduledDateTime = DateTime(2026, 6, 23, 8);

      for (final status in [
        IntakeStatus.taken,
        IntakeStatus.skipped,
        IntakeStatus.missed,
      ]) {
        final candidates = MissedIntakePlanner.findCandidates(
          therapies: [_therapy(medicine)],
          records: [
            IntakeRecord(
              id: 'record-$status',
              medicineId: medicine.id,
              profileId: 'profile-1',
              scheduledDateTime: scheduledDateTime,
              status: status,
              medicineNameSnapshot: medicine.name,
            ),
          ],
          referenceDate: referenceDate,
          lookbackDays: 1,
        );

        expect(candidates, isEmpty);
      }
    },
  );

  test('does not create missed candidates for todays scheduled intakes', () {
    final medicine = _medicine(daysOfWeek: [referenceDate.weekday]);
    final candidates = MissedIntakePlanner.findCandidates(
      therapies: [_therapy(medicine)],
      records: const [],
      referenceDate: referenceDate,
      lookbackDays: 1,
    );

    expect(candidates, isEmpty);
  });

  test('does not recreate candidates on a subsequent app start', () {
    final medicine = _medicine(daysOfWeek: [yesterday.weekday]);
    final firstCandidates = MissedIntakePlanner.findCandidates(
      therapies: [_therapy(medicine)],
      records: const [],
      referenceDate: referenceDate,
      lookbackDays: 1,
    );

    final recordsAfterFirstStart = firstCandidates
        .map(
          (candidate) => IntakeRecord(
            id: 'missed-${candidate.medicine.id}',
            medicineId: candidate.medicine.id,
            profileId: 'profile-1',
            scheduledDateTime: candidate.scheduledDateTime,
            status: IntakeStatus.missed,
            medicineNameSnapshot: candidate.medicine.name,
          ),
        )
        .toList();
    final secondCandidates = MissedIntakePlanner.findCandidates(
      therapies: [_therapy(medicine)],
      records: recordsAfterFirstStart,
      referenceDate: referenceDate,
      lookbackDays: 1,
    );

    expect(firstCandidates, hasLength(1));
    expect(secondCandidates, isEmpty);
  });
}

Medicine _medicine({
  required List<int> daysOfWeek,
  DateTime? createdAt,
  DateTime? scheduleCreatedAt,
}) {
  final now = createdAt ?? DateTime(2026, 6, 1);
  return Medicine(
    id: 'medicine-1',
    profileId: 'profile-1',
    therapyId: 'therapy-1',
    name: 'Medicina di prova',
    dose: '1 compressa',
    times: const [TimeOfDay(hour: 8, minute: 0)],
    daysOfWeek: daysOfWeek,
    schedules: [
      MedicineSchedule(
        time: const TimeOfDay(hour: 8, minute: 0),
        daysOfWeek: daysOfWeek,
        createdAt: scheduleCreatedAt,
      ),
    ],
    stockQuantity: 10.0,
    stockWarningThreshold: 2.0,
    createdAt: now,
    updatedAt: now,
  );
}

Therapy _therapy(Medicine medicine) => Therapy(
  id: 'therapy-1',
  profileId: 'profile-1',
  name: 'Terapia di prova',
  color: '#2E7D32',
  medicines: [medicine],
);
