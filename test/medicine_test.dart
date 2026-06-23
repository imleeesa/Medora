import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/medicine.dart';

void main() {
  test('uses a readable fallback when the dose is not specified', () {
    final now = DateTime(2026, 6, 22);
    final medicine = Medicine(
      id: 'medicine-1',
      name: 'Medicina di prova',
      dose: '',
      times: const [TimeOfDay(hour: 8, minute: 0)],
      daysOfWeek: const [1],
      stockQuantity: 10,
      stockWarningThreshold: 2,
      createdAt: now,
      updatedAt: now,
    );

    expect(medicine.doseLabel, 'Dose non specificata');
  });

  test('preserves medicine data when moving to another therapy', () {
    final now = DateTime(2026, 6, 24);
    final medicine = Medicine(
      id: 'medicine-1',
      therapyId: 'therapy-a',
      name: 'Medicina di prova',
      dose: '1 compressa',
      times: const [TimeOfDay(hour: 8, minute: 0)],
      daysOfWeek: const [1],
      stockQuantity: 10,
      stockWarningThreshold: 2,
      createdAt: now,
      updatedAt: now,
    );

    final movedMedicine = medicine.copyWith(
      therapyId: 'therapy-b',
      updatedAt: now.add(const Duration(minutes: 1)),
    );

    expect(movedMedicine.therapyId, 'therapy-b');
    expect(movedMedicine.name, medicine.name);
    expect(movedMedicine.schedules, medicine.schedules);
  });
}
