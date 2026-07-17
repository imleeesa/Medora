import 'package:flutter/material.dart';

import '../models/medicine.dart';
import '../models/medicine_schedule.dart';
import 'weekday_labels.dart';

/// Un gruppo di programmazione per la UI: uno stesso set di giorni con uno o
/// piu' orari (es. "Lun, Mer, Ven - 08:00, 20:00"). Solo presentazione: non
/// rappresenta una nuova entita' di dominio e non altera gli schedule
/// atomici reali (`MedicineSchedule`).
class ScheduleDisplayGroup {
  final List<int> daysOfWeek;
  final List<TimeOfDay> times;

  const ScheduleDisplayGroup({required this.daysOfWeek, required this.times});
}

/// Helper condiviso di sola presentazione per raggruppare gli schedule reali
/// di una medicina in righe leggibili, usato sia dal form (per editing) sia
/// dal dettaglio medicina (per la sola visualizzazione). Prima di questo
/// helper la stessa identica logica era duplicata in
/// `add_medicine_screen.dart` e `medicine_detail_screen.dart`, con rischio di
/// divergenza silenziosa tra ciò che l'utente modifica e ciò che vede.
///
/// Regola fondamentale: opera SEMPRE su `MedicineSchedule` gia' atomici
/// (medicineId + giorni + orario reali). Non ricostruisce mai slot facendo
/// il prodotto cartesiano tra un elenco di orari e un elenco di giorni non
/// correlati tra loro: raggruppa solo schedule che condividono esattamente
/// lo stesso set di giorni.
class ScheduleGrouping {
  const ScheduleGrouping._();

  /// Raggruppa gli schedule attivi di [medicine] per set di giorni.
  ///
  /// Se non esiste alcuno schedule atomico attivo (dato legacy pre
  /// migrazione), ricade - SOLO per display - sulle viste derivate
  /// `medicine.times`/`medicine.daysOfWeek`. Questo fallback esiste
  /// unicamente per non mostrare una schermata vuota su dati legacy: non
  /// deve mai essere usato per generare nuove assunzioni operative (quelle
  /// restano sempre basate sugli schedule atomici reali in
  /// `MedicineProvider`).
  static List<ScheduleDisplayGroup> groupsFor(Medicine medicine) {
    final activeSchedules = medicine.schedules
        .where((schedule) => schedule.isActive)
        .toList(growable: false);
    final source = activeSchedules.isNotEmpty
        ? activeSchedules
        : _legacyDisplayOnlyFallback(medicine);
    return groupSchedules(source);
  }

  /// Raggruppa una lista di [MedicineSchedule] gia' atomici per set di
  /// giorni condiviso. Ogni schedule in ingresso rappresenta gia' un orario
  /// reale con i suoi giorni reali: qui si limita a unire per display gli
  /// schedule che condividono lo stesso set di giorni, mai a incrociare
  /// giorni e orari provenienti da schedule diversi.
  static List<ScheduleDisplayGroup> groupSchedules(
    Iterable<MedicineSchedule> schedules,
  ) {
    final daysByTimeKey = <String, Set<int>>{};
    final timeByKey = <String, TimeOfDay>{};

    for (final schedule in schedules) {
      final days = uniqueSortedDays(schedule.daysOfWeek);
      if (days.isEmpty) continue;
      final key = _timeKey(schedule.time);
      timeByKey[key] = schedule.time;
      daysByTimeKey.putIfAbsent(key, () => <int>{}).addAll(days);
    }

    final timesByDaysKey = <String, List<TimeOfDay>>{};
    final daysByDaysKey = <String, List<int>>{};
    for (final entry in daysByTimeKey.entries) {
      final days = uniqueSortedDays(entry.value);
      final daysKey = days.join(',');
      daysByDaysKey[daysKey] = days;
      timesByDaysKey
          .putIfAbsent(daysKey, () => <TimeOfDay>[])
          .add(timeByKey[entry.key]!);
    }

    final groups = timesByDaysKey.entries
        .map(
          (entry) => ScheduleDisplayGroup(
            daysOfWeek: daysByDaysKey[entry.key]!,
            times: uniqueSortedTimes(entry.value),
          ),
        )
        .toList();

    groups.sort((first, second) {
      final firstDay = first.daysOfWeek.isEmpty ? 8 : first.daysOfWeek.first;
      final secondDay = second.daysOfWeek.isEmpty ? 8 : second.daysOfWeek.first;
      if (firstDay != secondDay) return firstDay.compareTo(secondDay);
      final firstTime = first.times.isEmpty
          ? const TimeOfDay(hour: 23, minute: 59)
          : first.times.first;
      final secondTime = second.times.isEmpty
          ? const TimeOfDay(hour: 23, minute: 59)
          : second.times.first;
      return compareTimeOfDay(firstTime, secondTime);
    });
    return groups;
  }

  /// Fallback SOLO display quando `medicine.schedules` non contiene entry
  /// attive. Usa le viste derivate di compatibilita' (unione storica di
  /// giorni/orari): puo' rappresentare in modo impreciso medicine con
  /// programmazioni realmente diverse per fascia, ma si applica solo a dati
  /// legacy senza schedule atomici, quindi non esiste un dato piu' preciso
  /// da mostrare.
  static List<MedicineSchedule> _legacyDisplayOnlyFallback(Medicine medicine) {
    return medicine.times
        .map(
          (time) =>
              MedicineSchedule(time: time, daysOfWeek: medicine.daysOfWeek),
        )
        .toList(growable: false);
  }

  static String _timeKey(TimeOfDay time) => '${time.hour}:${time.minute}';

  static List<int> uniqueSortedDays(Iterable<int> days) {
    return days.toSet().where((day) => day >= 1 && day <= 7).toList()..sort();
  }

  static List<TimeOfDay> uniqueSortedTimes(Iterable<TimeOfDay> times) {
    final unique = <String, TimeOfDay>{};
    for (final time in times) {
      unique[_timeKey(time)] = time;
    }
    return unique.values.toList(growable: false)..sort(compareTimeOfDay);
  }

  static int compareTimeOfDay(TimeOfDay first, TimeOfDay second) {
    final firstMinutes = first.hour * 60 + first.minute;
    final secondMinutes = second.hour * 60 + second.minute;
    return firstMinutes.compareTo(secondMinutes);
  }

  /// Etichetta breve dei giorni, es. "Lun, Mer, Ven" o "Tutti i giorni".
  static String dayNames(List<int> days, {bool allDaysLabel = true}) {
    final safeDays = uniqueSortedDays(days);
    if (allDaysLabel && safeDays.length == 7) return 'Tutti i giorni';
    return safeDays.map((day) => kWeekdayShortLabels[day - 1]).join(', ');
  }

  /// Etichetta breve degli orari nel formato locale (12h/24h di sistema).
  static String timeNames(BuildContext context, List<TimeOfDay> times) {
    return uniqueSortedTimes(
      times,
    ).map((time) => time.format(context)).join(', ');
  }
}
