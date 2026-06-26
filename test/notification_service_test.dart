import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/services/notification_service.dart';
import 'package:meditrack/services/notification_payload.dart';

void main() {
  test('uses stable unique ids for medicine schedule slots', () {
    final first = NotificationService.notificationIdFor(
      medicineId: 'medicine-1',
      dayOfWeek: DateTime.monday,
      hour: 8,
      minute: 0,
    );
    final sameSlot = NotificationService.notificationIdFor(
      medicineId: 'medicine-1',
      dayOfWeek: DateTime.monday,
      hour: 8,
      minute: 0,
    );
    final differentSlot = NotificationService.notificationIdFor(
      medicineId: 'medicine-1',
      dayOfWeek: DateTime.wednesday,
      hour: 8,
      minute: 0,
    );

    expect(first, sameSlot);
    expect(first, isNot(differentSlot));
    expect(first, greaterThanOrEqualTo(0));
  });

  test('builds reminder bodies with an optional dose', () {
    expect(
      NotificationService.reminderBody(_medicine(dose: '1/2 pastiglia')),
      'E ora di prendere Aspirina - 1/2 pastiglia',
    );
    expect(
      NotificationService.reminderBody(_medicine(dose: '')),
      'E ora di prendere Aspirina',
    );
  });

  test('builds a stable payload for notification actions', () {
    final payload = NotificationService.payloadFor(
      medicineId: 'medicine-1',
      dayOfWeek: DateTime.monday,
      hour: 8,
      minute: 30,
    );
    final decoded = MedicineNotificationPayload.tryDecode(payload);

    expect(decoded, isNotNull);
    expect(decoded!.medicineId, 'medicine-1');
    expect(decoded.dayOfWeek, DateTime.monday);
    expect(decoded.hour, 8);
    expect(decoded.minute, 30);
    expect(
      decoded.scheduledDateTime(referenceDate: DateTime(2026, 6, 24, 9)),
      DateTime(2026, 6, 22, 8, 30),
    );
  });
}

Medicine _medicine({required String dose}) {
  final now = DateTime(2026, 6, 24);
  return Medicine(
    id: 'medicine-1',
    profileId: 'profile-1',
    therapyId: 'therapy-1',
    name: 'Aspirina',
    dose: dose,
    times: const [TimeOfDay(hour: 8, minute: 0)],
    daysOfWeek: const [DateTime.monday],
    stockQuantity: 10,
    stockWarningThreshold: 2,
    createdAt: now,
    updatedAt: now,
  );
}
