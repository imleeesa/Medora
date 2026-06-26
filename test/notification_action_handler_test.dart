import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/intake_record.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/models/medicine_schedule.dart';
import 'package:meditrack/models/user_profile.dart';
import 'package:meditrack/repositories/intake_repository.dart';
import 'package:meditrack/repositories/medicine_repository.dart';
import 'package:meditrack/repositories/profile_repository.dart';
import 'package:meditrack/services/intake_action_service.dart';
import 'package:meditrack/services/notification_action_handler.dart';
import 'package:meditrack/services/notification_service.dart';

void main() {
  group('NotificationActionHandler', () {
    test('Assunta creates a taken record and decrements stock once', () async {
      final fixture = _ActionFixture(
        medicine: _medicine(dose: '1/2 pastiglia', stockQuantity: 10),
      );
      final payload = _payload();

      final firstResult = await fixture.handler.handle(
        actionId: NotificationActionIds.taken,
        payload: payload,
        referenceDate: DateTime(2026, 6, 22, 8, 5),
      );
      final secondResult = await fixture.handler.handle(
        actionId: NotificationActionIds.taken,
        payload: payload,
        referenceDate: DateTime(2026, 6, 22, 8, 6),
      );

      expect(firstResult, isTrue);
      expect(secondResult, isTrue);
      expect(fixture.intakeRepository.records, hasLength(1));
      expect(
        fixture.intakeRepository.records.single.status,
        IntakeStatus.taken,
      );
      expect(
        fixture.intakeRepository.records.single.scheduledDateTime,
        DateTime(2026, 6, 22, 8),
      );
      expect(fixture.medicineRepository.medicine.stockQuantity, 9.5);
    });

    test(
      'Saltata creates a skipped record without decrementing stock',
      () async {
        final fixture = _ActionFixture(
          medicine: _medicine(dose: '1 compressa', stockQuantity: 10),
        );

        final result = await fixture.handler.handle(
          actionId: NotificationActionIds.skipped,
          payload: _payload(),
          referenceDate: DateTime(2026, 6, 22, 8, 5),
        );

        expect(result, isTrue);
        expect(fixture.intakeRepository.records, hasLength(1));
        expect(
          fixture.intakeRepository.records.single.status,
          IntakeStatus.skipped,
        );
        expect(fixture.medicineRepository.medicine.stockQuantity, 10);
      },
    );

    test(
      'skipped to taken decrements stock and does not duplicate records',
      () async {
        final fixture = _ActionFixture(
          medicine: _medicine(dose: '1 compressa', stockQuantity: 10),
        );
        final payload = _payload();

        await fixture.handler.handle(
          actionId: NotificationActionIds.skipped,
          payload: payload,
          referenceDate: DateTime(2026, 6, 22, 8, 5),
        );
        await fixture.handler.handle(
          actionId: NotificationActionIds.taken,
          payload: payload,
          referenceDate: DateTime(2026, 6, 22, 8, 6),
        );

        expect(fixture.intakeRepository.records, hasLength(1));
        expect(
          fixture.intakeRepository.records.single.status,
          IntakeStatus.taken,
        );
        expect(fixture.medicineRepository.medicine.stockQuantity, 9);
      },
    );

    test('taken to skipped restores the exact stock amount', () async {
      final fixture = _ActionFixture(
        medicine: _medicine(dose: '1/4 pastiglia', stockQuantity: 10),
      );
      final payload = _payload();

      await fixture.handler.handle(
        actionId: NotificationActionIds.taken,
        payload: payload,
        referenceDate: DateTime(2026, 6, 22, 8, 5),
      );
      await fixture.handler.handle(
        actionId: NotificationActionIds.skipped,
        payload: payload,
        referenceDate: DateTime(2026, 6, 22, 8, 6),
      );

      expect(fixture.intakeRepository.records, hasLength(1));
      expect(
        fixture.intakeRepository.records.single.status,
        IntakeStatus.skipped,
      );
      expect(fixture.medicineRepository.medicine.stockQuantity, 10);
    });

    test('insufficient stock returns false without partial updates', () async {
      final fixture = _ActionFixture(
        medicine: _medicine(dose: '1/2 pastiglia', stockQuantity: 0.25),
      );

      final result = await fixture.handler.handle(
        actionId: NotificationActionIds.taken,
        payload: _payload(),
        referenceDate: DateTime(2026, 6, 22, 8, 5),
      );

      expect(result, isFalse);
      expect(fixture.intakeRepository.records, isEmpty);
      expect(fixture.medicineRepository.medicine.stockQuantity, 0.25);
    });

    test('invalid action or payload is ignored safely', () async {
      final fixture = _ActionFixture(
        medicine: _medicine(dose: '1 compressa', stockQuantity: 10),
      );

      expect(
        await fixture.handler.handle(
          actionId: 'unknown',
          payload: _payload(),
          referenceDate: DateTime(2026, 6, 22, 8, 5),
        ),
        isFalse,
      );
      expect(
        await fixture.handler.handle(
          actionId: NotificationActionIds.taken,
          payload: 'not-json',
          referenceDate: DateTime(2026, 6, 22, 8, 5),
        ),
        isFalse,
      );
      expect(fixture.intakeRepository.records, isEmpty);
    });
  });
}

class _ActionFixture {
  _ActionFixture({required Medicine medicine})
    : profileRepository = _FakeProfileRepository(),
      medicineRepository = _FakeMedicineRepository(medicine),
      intakeRepository = _FakeIntakeRepository() {
    intakeRepository.onUpdateMedicine = (medicine) {
      medicineRepository.medicine = medicine;
    };
    handler = NotificationActionHandler(
      intakeActionService: IntakeActionService(
        profileRepository: profileRepository,
        medicineRepository: medicineRepository,
        intakeRepository: intakeRepository,
      ),
    );
  }

  final _FakeProfileRepository profileRepository;
  final _FakeMedicineRepository medicineRepository;
  final _FakeIntakeRepository intakeRepository;
  late final NotificationActionHandler handler;
}

class _FakeProfileRepository implements ProfileRepository {
  final profile = UserProfile(
    id: 'profile-1',
    name: 'Utente',
    createdAt: DateTime(2026, 6, 22),
    updatedAt: DateTime(2026, 6, 22),
  );

  @override
  Future<void> createProfile(UserProfile profile) async {}

  @override
  Future<UserProfile?> getCurrentProfile() async => profile;

  @override
  Future<UserProfile?> getProfileById(String profileId) async =>
      profile.id == profileId ? profile : null;

  @override
  Future<bool> updateProfile(UserProfile profile) async => true;
}

class _FakeMedicineRepository implements MedicineRepository {
  _FakeMedicineRepository(this.medicine);

  Medicine medicine;

  @override
  Future<void> createMedicine(Medicine medicine) async {
    this.medicine = medicine;
  }

  @override
  Future<void> deleteMedicine(String medicineId) async {}

  @override
  Future<List<Medicine>> getLowStockMedicines(String profileId) async =>
      medicine.stockQuantity <= medicine.stockWarningThreshold
      ? [medicine]
      : const [];

  @override
  Future<List<Medicine>> getMedicines(String profileId) async => [medicine];

  @override
  Future<List<Medicine>> getMedicinesByTherapy(String therapyId) async =>
      medicine.therapyId == therapyId ? [medicine] : const [];

  @override
  Future<List<MedicineSchedule>> getSchedulesForMedicine(
    String medicineId,
  ) async => medicine.schedules;

  @override
  Future<void> replaceSchedules(
    String medicineId,
    List<MedicineSchedule> schedules,
  ) async {
    medicine = medicine.copyWith(schedules: schedules);
  }

  @override
  Future<bool> updateMedicine(Medicine medicine) async {
    this.medicine = medicine;
    return true;
  }

  @override
  Stream<List<Medicine>> watchMedicines(String profileId) =>
      Stream.value([medicine]);
}

class _FakeIntakeRepository implements IntakeRepository {
  final records = <IntakeRecord>[];
  void Function(Medicine medicine)? onUpdateMedicine;

  @override
  Future<void> createIntakeRecord(IntakeRecord record) async {
    records.add(record);
  }

  @override
  Future<void> createIntakeRecords(List<IntakeRecord> records) async {
    this.records.addAll(records);
  }

  @override
  Future<IntakeRecord?> getIntakeRecordForSchedule({
    required String medicineId,
    required DateTime scheduledDateTime,
  }) async => records
      .where(
        (record) =>
            record.medicineId == medicineId &&
            record.scheduledDateTime == scheduledDateTime,
      )
      .firstOrNull;

  @override
  Future<List<IntakeRecord>> getIntakeRecords(String profileId) async =>
      records;

  @override
  Future<List<IntakeRecord>> getIntakeRecordsByMedicine(
    String medicineId,
  ) async => records
      .where((record) => record.medicineId == medicineId)
      .toList(growable: false);

  @override
  Future<void> saveIntakeRecordWithStock({
    required IntakeRecord record,
    required bool updateExistingRecord,
    Medicine? updatedMedicine,
  }) async {
    if (updatedMedicine != null) {
      onUpdateMedicine?.call(updatedMedicine);
    }
    if (updateExistingRecord) {
      final index = records.indexWhere((item) => item.id == record.id);
      if (index == -1) {
        throw StateError('Record not found.');
      }
      records[index] = record;
    } else {
      records.add(record);
    }
  }

  @override
  Future<bool> updateIntakeRecord(IntakeRecord record) async {
    final index = records.indexWhere((item) => item.id == record.id);
    if (index == -1) return false;
    records[index] = record;
    return true;
  }
}

String _payload() {
  return NotificationService.payloadFor(
    medicineId: 'medicine-1',
    dayOfWeek: DateTime.monday,
    hour: 8,
    minute: 0,
  );
}

Medicine _medicine({required String dose, required double stockQuantity}) {
  final now = DateTime(2026, 6, 22);
  return Medicine(
    id: 'medicine-1',
    profileId: 'profile-1',
    therapyId: 'therapy-1',
    name: 'Aspirina',
    dose: dose,
    times: const [TimeOfDay(hour: 8, minute: 0)],
    daysOfWeek: const [DateTime.monday],
    stockQuantity: stockQuantity,
    stockWarningThreshold: 2,
    createdAt: now,
    updatedAt: now,
  );
}
