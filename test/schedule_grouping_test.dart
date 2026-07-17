import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/models/medicine_schedule.dart';
import 'package:meditrack/utils/schedule_grouping.dart';

Medicine _medicine({
  required List<TimeOfDay> times,
  required List<int> daysOfWeek,
  List<MedicineSchedule>? schedules,
}) {
  final now = DateTime(2026, 1, 1);
  return Medicine(
    id: 'medicine-1',
    name: 'Medicina',
    dose: '',
    times: times,
    daysOfWeek: daysOfWeek,
    stockQuantity: 10,
    stockWarningThreshold: 3,
    schedules: schedules,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ScheduleGrouping', () {
    test('una singola programmazione produce un solo gruppo', () {
      final medicine = _medicine(
        times: const [TimeOfDay(hour: 8, minute: 0)],
        daysOfWeek: const [DateTime.monday, DateTime.wednesday],
        schedules: const [
          MedicineSchedule(
            time: TimeOfDay(hour: 8, minute: 0),
            daysOfWeek: [DateTime.monday, DateTime.wednesday],
          ),
        ],
      );

      final groups = ScheduleGrouping.groupsFor(medicine);

      expect(groups, hasLength(1));
      expect(groups.single.daysOfWeek, [DateTime.monday, DateTime.wednesday]);
      expect(groups.single.times, [const TimeOfDay(hour: 8, minute: 0)]);
    });

    test('più programmazioni con giorni diversi restano gruppi separati', () {
      final medicine = _medicine(
        times: const [],
        daysOfWeek: const [],
        schedules: const [
          MedicineSchedule(
            time: TimeOfDay(hour: 8, minute: 0),
            daysOfWeek: [DateTime.monday],
          ),
          MedicineSchedule(
            time: TimeOfDay(hour: 20, minute: 30),
            daysOfWeek: [DateTime.saturday, DateTime.sunday],
          ),
        ],
      );

      final groups = ScheduleGrouping.groupsFor(medicine);

      expect(groups, hasLength(2));
      expect(groups[0].daysOfWeek, [DateTime.monday]);
      expect(groups[0].times, [const TimeOfDay(hour: 8, minute: 0)]);
      expect(groups[1].daysOfWeek, [DateTime.saturday, DateTime.sunday]);
      expect(groups[1].times, [const TimeOfDay(hour: 20, minute: 30)]);
    });

    test(
      'schedule con stessi giorni ma orari diversi si uniscono in un gruppo',
      () {
        final medicine = _medicine(
          times: const [],
          daysOfWeek: const [],
          schedules: const [
            MedicineSchedule(
              time: TimeOfDay(hour: 8, minute: 0),
              daysOfWeek: [DateTime.monday],
            ),
            MedicineSchedule(
              time: TimeOfDay(hour: 20, minute: 30),
              daysOfWeek: [DateTime.monday],
            ),
          ],
        );

        final groups = ScheduleGrouping.groupsFor(medicine);

        expect(groups, hasLength(1));
        expect(groups.single.daysOfWeek, [DateTime.monday]);
        expect(groups.single.times, [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 30),
        ]);
      },
    );

    test(
      'schedule con stesso orario ma giorni diversi si uniscono in un gruppo',
      () {
        final medicine = _medicine(
          times: const [],
          daysOfWeek: const [],
          schedules: const [
            MedicineSchedule(
              time: TimeOfDay(hour: 13, minute: 53),
              daysOfWeek: [DateTime.monday],
            ),
            MedicineSchedule(
              time: TimeOfDay(hour: 13, minute: 53),
              daysOfWeek: [DateTime.wednesday],
            ),
          ],
        );

        final groups = ScheduleGrouping.groupsFor(medicine);

        expect(groups, hasLength(1));
        expect(groups.single.daysOfWeek, [DateTime.monday, DateTime.wednesday]);
        expect(groups.single.times, [const TimeOfDay(hour: 13, minute: 53)]);
        expect(ScheduleGrouping.dayNames(groups.single.daysOfWeek), 'Lun, Mer');
      },
    );

    test(
      'senza schedule attivi ricade sul fallback legacy times/daysOfWeek solo per display',
      () {
        final medicine = _medicine(
          times: const [
            TimeOfDay(hour: 8, minute: 0),
            TimeOfDay(hour: 20, minute: 30),
          ],
          daysOfWeek: const [DateTime.monday],
          schedules: const [],
        );

        final groups = ScheduleGrouping.groupsFor(medicine);

        expect(groups, hasLength(1));
        expect(groups.single.daysOfWeek, [DateTime.monday]);
        expect(groups.single.times, [
          const TimeOfDay(hour: 8, minute: 0),
          const TimeOfDay(hour: 20, minute: 30),
        ]);
      },
    );

    test(
      'il fallback legacy non genera un prodotto cartesiano tra orari e giorni non correlati',
      () {
        // Due schedule atomici reali con giorni diversi tra loro: se il
        // raggruppamento facesse un prodotto cartesiano, un singolo giorno
        // finirebbe per essere associato anche all'orario dell'altro
        // schedule. Qui verifichiamo che ogni gruppo prodotto resti fedele
        // esattamente ai giorni dello schedule atomico da cui proviene.
        final medicine = _medicine(
          times: const [],
          daysOfWeek: const [],
          schedules: const [
            MedicineSchedule(
              time: TimeOfDay(hour: 8, minute: 0),
              daysOfWeek: [DateTime.monday],
            ),
            MedicineSchedule(
              time: TimeOfDay(hour: 20, minute: 30),
              daysOfWeek: [DateTime.friday],
            ),
          ],
        );

        final groups = ScheduleGrouping.groupsFor(medicine);

        expect(groups, hasLength(2));
        final mondayGroup = groups.firstWhere(
          (group) => group.daysOfWeek.contains(DateTime.monday),
        );
        final fridayGroup = groups.firstWhere(
          (group) => group.daysOfWeek.contains(DateTime.friday),
        );
        expect(mondayGroup.daysOfWeek, [DateTime.monday]);
        expect(mondayGroup.times, [const TimeOfDay(hour: 8, minute: 0)]);
        expect(fridayGroup.daysOfWeek, [DateTime.friday]);
        expect(fridayGroup.times, [const TimeOfDay(hour: 20, minute: 30)]);
      },
    );

    test('gli schedule disattivati vengono esclusi dal display', () {
      final medicine = _medicine(
        times: const [],
        daysOfWeek: const [],
        schedules: const [
          MedicineSchedule(
            time: TimeOfDay(hour: 8, minute: 0),
            daysOfWeek: [DateTime.monday],
            isActive: false,
          ),
          MedicineSchedule(
            time: TimeOfDay(hour: 20, minute: 30),
            daysOfWeek: [DateTime.monday],
          ),
        ],
      );

      final groups = ScheduleGrouping.groupsFor(medicine);

      expect(groups, hasLength(1));
      expect(groups.single.times, [const TimeOfDay(hour: 20, minute: 30)]);
    });

    test('dayNames restituisce "Tutti i giorni" per tutti e 7 i giorni', () {
      expect(
        ScheduleGrouping.dayNames(const [1, 2, 3, 4, 5, 6, 7]),
        'Tutti i giorni',
      );
    });
  });
}
