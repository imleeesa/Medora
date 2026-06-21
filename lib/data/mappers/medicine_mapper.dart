import 'package:drift/drift.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../models/medicine.dart' as app;
import '../../models/medicine_schedule.dart' as app_schedule;
import '../local_database.dart' as db;
import 'color_value_mapper.dart';

class MedicineMapper {
  const MedicineMapper._();

  static app.Medicine fromDatabase(
    db.Medicine medicine,
    List<db.MedicineSchedule> scheduleRows,
  ) {
    final schedules = _groupSchedules(scheduleRows);
    final times = schedules.map((schedule) => schedule.time).toList();
    final daysOfWeek =
        schedules.expand((schedule) => schedule.daysOfWeek).toSet().toList()
          ..sort();

    return app.Medicine(
      id: medicine.id,
      profileId: medicine.profileId,
      therapyId: medicine.therapyId,
      name: medicine.name,
      dose: medicine.dose,
      notes: medicine.notes,
      color: ColorValueMapper.fromColorValue(medicine.colorValue),
      iconCodePoint: medicine.iconCodePoint,
      times: times,
      daysOfWeek: daysOfWeek,
      schedules: schedules,
      stockQuantity: medicine.stockQuantity,
      stockWarningThreshold: medicine.stockWarningThreshold,
      isActive: medicine.isActive,
      createdAt: medicine.createdAt,
      updatedAt: medicine.updatedAt,
    );
  }

  static db.MedicinesCompanion toCompanion(app.Medicine medicine) {
    final profileId = medicine.profileId;
    if (profileId == null) {
      throw StateError('A medicine must have a profileId before persistence.');
    }

    return db.MedicinesCompanion.insert(
      id: medicine.id,
      profileId: profileId,
      therapyId: Value(medicine.therapyId),
      name: medicine.name,
      dose: medicine.dose,
      notes: Value(medicine.notes),
      colorValue: ColorValueMapper.toColorValue(medicine.color),
      iconCodePoint: medicine.iconCodePoint ?? 0,
      stockQuantity: medicine.stockQuantity,
      stockWarningThreshold: medicine.stockWarningThreshold,
      isActive: medicine.isActive,
      createdAt: medicine.createdAt,
      updatedAt: medicine.updatedAt,
    );
  }

  static List<db.MedicineSchedulesCompanion> toScheduleCompanions(
    String medicineId,
    List<app_schedule.MedicineSchedule> schedules,
  ) {
    final now = DateTime.now();
    final companions = <db.MedicineSchedulesCompanion>[];

    for (final schedule in schedules) {
      final daysOfWeek = schedule.daysOfWeek.toSet().toList()..sort();
      for (final dayOfWeek in daysOfWeek) {
        if (dayOfWeek < 1 || dayOfWeek > 7) {
          throw ArgumentError.value(
            dayOfWeek,
            'dayOfWeek',
            'Must be between 1 and 7.',
          );
        }
        companions.add(
          db.MedicineSchedulesCompanion.insert(
            id: const Uuid().v4(),
            medicineId: medicineId,
            hour: schedule.time.hour,
            minute: schedule.time.minute,
            dayOfWeek: dayOfWeek,
            isActive: schedule.isActive,
            createdAt: schedule.createdAt ?? now,
            updatedAt: schedule.updatedAt ?? now,
          ),
        );
      }
    }

    return companions;
  }

  static List<app_schedule.MedicineSchedule> schedulesFromDatabase(
    List<db.MedicineSchedule> rows,
  ) {
    return _groupSchedules(rows);
  }

  static List<app_schedule.MedicineSchedule> _groupSchedules(
    List<db.MedicineSchedule> rows,
  ) {
    final groupedRows = <String, List<db.MedicineSchedule>>{};
    for (final row in rows) {
      final key = '${row.hour}:${row.minute}:${row.isActive}';
      groupedRows.putIfAbsent(key, () => []).add(row);
    }

    final schedules = groupedRows.values.map((group) {
      final first = group.first;
      final daysOfWeek = group.map((row) => row.dayOfWeek).toSet().toList()
        ..sort();
      return app_schedule.MedicineSchedule(
        time: TimeOfDay(hour: first.hour, minute: first.minute),
        daysOfWeek: daysOfWeek,
        isActive: first.isActive,
        createdAt: first.createdAt,
        updatedAt: first.updatedAt,
      );
    }).toList();

    schedules.sort((first, second) {
      final timeOrder = first.time.hour.compareTo(second.time.hour);
      if (timeOrder != 0) return timeOrder;
      return first.time.minute.compareTo(second.time.minute);
    });
    return schedules;
  }
}
