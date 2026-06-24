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
      stockQuantity: 10.0,
      stockWarningThreshold: 2.0,
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
      stockQuantity: 10.0,
      stockWarningThreshold: 2.0,
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

  test('extracts integer, fractional and decimal quantities from doses', () {
    expect(Medicine.stockConsumptionAmountFromDose('1 compressa'), 1.0);
    expect(Medicine.stockConsumptionAmountFromDose('1/2 pastiglia'), 0.5);
    expect(Medicine.stockConsumptionAmountFromDose('1/4 pastiglia'), 0.25);
    expect(Medicine.stockConsumptionAmountFromDose('2.5 ml'), 2.5);
    expect(Medicine.stockConsumptionAmountFromDose('0,5 ml'), 0.5);
    expect(Medicine.stockConsumptionAmountFromDose(''), isNull);
  });

  test('formats stock quantities without unnecessary decimals', () {
    expect(Medicine.formatQuantity(10.0), '10');
    expect(Medicine.formatQuantity(2.5), '2.5');
    expect(Medicine.formatQuantity(0.25), '0.25');
    expect(Medicine.normalizeQuantity(0.3 - 0.1 - 0.2), 0.0);
  });
}
