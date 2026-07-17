import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/intake_record.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/models/medicine_schedule.dart';
import 'package:meditrack/models/therapy.dart';
import 'package:meditrack/models/user_profile.dart';
import 'package:meditrack/repositories/intake_repository.dart';
import 'package:meditrack/repositories/medicine_repository.dart';
import 'package:meditrack/repositories/profile_repository.dart';
import 'package:meditrack/repositories/therapy_repository.dart';
import 'package:meditrack/services/intake_action_service.dart';

/// Test di regressione: un'azione Assunta/Saltata deve aggiornare SOLO il
/// record della medicina selezionata. Record orfani (medicina eliminata,
/// medicineId null, "Terapia non disponibile") e record di altre medicine
/// che condividono data/orario non devono mai essere toccati.
void main() {
  group('IntakeActionService record isolation', () {
    final scheduledDateTime = DateTime(2026, 7, 16, 8, 0);

    IntakeRecord orphanRecord({IntakeStatus status = IntakeStatus.skipped}) {
      return IntakeRecord(
        id: 'orphan-sasso',
        medicineId: null,
        profileId: 'profile-1',
        scheduledDateTime: scheduledDateTime,
        status: status,
        medicineNameSnapshot: 'sasso',
        medicineDoseSnapshot: '1 compressa',
        createdAt: DateTime(2026, 7, 1),
      );
    }

    test('un record orfano con Terapia non disponibile non viene modificato '
        'da una nuova Assunta allo stesso orario', () async {
      final fixture = _IsolationFixture(
        medicines: [_medicine(id: 'nuova-medicina', name: 'Nuova')],
        seededRecords: [orphanRecord()],
      );

      await fixture.service.markTaken(
        medicineId: 'nuova-medicina',
        scheduledDateTime: scheduledDateTime,
      );

      final orphan = fixture.intakeRepository.records
          .where((record) => record.id == 'orphan-sasso')
          .single;
      expect(orphan.status, IntakeStatus.skipped);
      expect(orphan.medicineId, isNull);
      expect(orphan.medicineNameSnapshot, 'sasso');

      final created = fixture.intakeRepository.records
          .where((record) => record.id != 'orphan-sasso')
          .single;
      expect(created.medicineId, 'nuova-medicina');
      expect(created.status, IntakeStatus.taken);
      expect(created.medicineNameSnapshot, 'Nuova');
    });

    test('due medicine attive allo stesso orario: Assunta aggiorna solo '
        'quella selezionata (record e scorte)', () async {
      final fixture = _IsolationFixture(
        medicines: [
          _medicine(id: 'med-a', name: 'Alfa', stockQuantity: 10),
          _medicine(id: 'med-b', name: 'Beta', stockQuantity: 10),
        ],
        seededRecords: [
          IntakeRecord(
            id: 'record-b',
            medicineId: 'med-b',
            profileId: 'profile-1',
            scheduledDateTime: scheduledDateTime,
            status: IntakeStatus.scheduled,
            medicineNameSnapshot: 'Beta',
            medicineDoseSnapshot: '1 compressa',
            createdAt: DateTime(2026, 7, 16),
          ),
        ],
      );

      await fixture.service.markTaken(
        medicineId: 'med-a',
        scheduledDateTime: scheduledDateTime,
      );

      final recordB = fixture.intakeRepository.records
          .where((record) => record.id == 'record-b')
          .single;
      expect(recordB.status, IntakeStatus.scheduled);
      expect(recordB.medicineId, 'med-b');

      final recordA = fixture.intakeRepository.records
          .where((record) => record.medicineId == 'med-a')
          .single;
      expect(recordA.status, IntakeStatus.taken);

      expect(fixture.medicineRepository.byId('med-a')!.stockQuantity, 9);
      expect(fixture.medicineRepository.byId('med-b')!.stockQuantity, 10);
    });

    test('una medicina eliminata non e aggiornabile: azione diretta fallisce e '
        'azione stale da notifica non scrive nulla', () async {
      final fixture = _IsolationFixture(
        medicines: [_medicine(id: 'esistente', name: 'Esistente')],
        seededRecords: [orphanRecord(status: IntakeStatus.taken)],
      );

      await expectLater(
        fixture.service.markTaken(
          medicineId: 'medicina-eliminata',
          scheduledDateTime: scheduledDateTime,
        ),
        throwsStateError,
      );

      await expectLater(
        fixture.service.markTakenFromNotification(
          medicineId: 'medicina-eliminata',
          scheduledDateTime: scheduledDateTime,
          dayOfWeek: scheduledDateTime.weekday,
          hour: 8,
          minute: 0,
          referenceDate: scheduledDateTime,
        ),
        throwsStateError,
      );

      expect(fixture.intakeRepository.records, hasLength(1));
      final orphan = fixture.intakeRepository.records.single;
      expect(orphan.id, 'orphan-sasso');
      expect(orphan.status, IntakeStatus.taken);
      expect(orphan.medicineNameSnapshot, 'sasso');
    });

    test('guardia difensiva: se il repository restituisse un record di '
        'un\'altra medicina, l\'azione fallisce senza scrivere', () async {
      final fixture = _IsolationFixture(
        medicines: [_medicine(id: 'med-a', name: 'Alfa')],
        seededRecords: [orphanRecord()],
      );
      fixture.intakeRepository.forceLooseMatch = true;

      await expectLater(
        fixture.service.markTaken(
          medicineId: 'med-a',
          scheduledDateTime: scheduledDateTime,
        ),
        throwsStateError,
      );

      expect(fixture.intakeRepository.records, hasLength(1));
      expect(
        fixture.intakeRepository.records.single.status,
        IntakeStatus.skipped,
      );
    });
  });
}

Medicine _medicine({
  required String id,
  required String name,
  double stockQuantity = 10,
}) {
  final now = DateTime(2026, 7, 1);
  return Medicine(
    id: id,
    profileId: 'profile-1',
    therapyId: 'therapy-1',
    name: name,
    dose: '1 compressa',
    times: const [TimeOfDay(hour: 8, minute: 0)],
    daysOfWeek: const [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ],
    stockQuantity: stockQuantity,
    stockWarningThreshold: 2,
    createdAt: now,
    updatedAt: now,
  );
}

class _IsolationFixture {
  _IsolationFixture({
    required List<Medicine> medicines,
    List<IntakeRecord> seededRecords = const [],
  }) : profileRepository = _FakeProfileRepository(),
       medicineRepository = _FakeMedicineRepository(medicines),
       therapyRepository = _FakeTherapyRepository(),
       intakeRepository = _FakeIntakeRepository() {
    intakeRepository.records.addAll(seededRecords);
    intakeRepository.onUpdateMedicine = medicineRepository.replaceMedicine;
    service = IntakeActionService(
      profileRepository: profileRepository,
      medicineRepository: medicineRepository,
      intakeRepository: intakeRepository,
      therapyRepository: therapyRepository,
    );
  }

  final _FakeProfileRepository profileRepository;
  final _FakeMedicineRepository medicineRepository;
  final _FakeTherapyRepository therapyRepository;
  final _FakeIntakeRepository intakeRepository;
  late final IntakeActionService service;
}

class _FakeProfileRepository implements ProfileRepository {
  final profile = UserProfile(
    id: 'profile-1',
    name: 'Utente',
    createdAt: DateTime(2026, 7, 1),
    updatedAt: DateTime(2026, 7, 1),
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
  _FakeMedicineRepository(List<Medicine> medicines)
    : _medicines = List.of(medicines);

  final List<Medicine> _medicines;

  Medicine? byId(String id) =>
      _medicines.where((medicine) => medicine.id == id).firstOrNull;

  void replaceMedicine(Medicine updated) {
    final index = _medicines.indexWhere(
      (medicine) => medicine.id == updated.id,
    );
    if (index != -1) _medicines[index] = updated;
  }

  @override
  Future<void> createMedicine(Medicine medicine) async {
    _medicines.add(medicine);
  }

  @override
  Future<void> deleteMedicine(String medicineId) async {
    _medicines.removeWhere((medicine) => medicine.id == medicineId);
  }

  @override
  Future<List<Medicine>> getLowStockMedicines(String profileId) async =>
      _medicines
          .where(
            (medicine) =>
                medicine.stockQuantity <= medicine.stockWarningThreshold,
          )
          .toList(growable: false);

  @override
  Future<List<Medicine>> getMedicines(String profileId) async =>
      List.of(_medicines);

  @override
  Future<List<Medicine>> getMedicinesByTherapy(String therapyId) async =>
      _medicines
          .where((medicine) => medicine.therapyId == therapyId)
          .toList(growable: false);

  @override
  Future<List<MedicineSchedule>> getSchedulesForMedicine(
    String medicineId,
  ) async => byId(medicineId)?.schedules ?? const [];

  @override
  Future<void> replaceSchedules(
    String medicineId,
    List<MedicineSchedule> schedules,
  ) async {
    final current = byId(medicineId);
    if (current != null) {
      replaceMedicine(current.copyWith(schedules: schedules));
    }
  }

  @override
  Future<bool> updateMedicine(Medicine medicine) async {
    replaceMedicine(medicine);
    return true;
  }

  @override
  Stream<List<Medicine>> watchMedicines(String profileId) =>
      Stream.value(List.of(_medicines));
}

class _FakeTherapyRepository implements TherapyRepository {
  @override
  Future<void> createTherapy(Therapy therapy) async {}

  @override
  Future<void> createTherapyWithMedicine(
    Therapy therapy,
    Medicine medicine,
  ) async {}

  @override
  Future<void> deleteTherapy(String therapyId) async {}

  @override
  Future<List<Therapy>> getTherapies(String profileId) async => [
    Therapy(
      id: 'therapy-1',
      profileId: profileId,
      name: 'Terapia',
      color: '#1E6B5A',
      medicines: const [],
      isActive: true,
    ),
  ];

  @override
  Future<bool> updateTherapy(Therapy therapy) async => true;

  @override
  Stream<List<Therapy>> watchTherapies(String profileId) =>
      Stream.fromFuture(getTherapies(profileId));
}

class _FakeIntakeRepository implements IntakeRepository {
  final records = <IntakeRecord>[];
  void Function(Medicine medicine)? onUpdateMedicine;

  /// Simula una regressione del repository (matching per solo orario):
  /// la guardia del service deve bloccare l'aggiornamento.
  bool forceLooseMatch = false;

  @override
  Future<void> createIntakeRecord(IntakeRecord record) async {
    records.add(record);
  }

  @override
  Future<void> createIntakeRecords(List<IntakeRecord> newRecords) async {
    records.addAll(newRecords);
  }

  @override
  Future<IntakeRecord?> getIntakeRecordForSchedule({
    required String medicineId,
    required DateTime scheduledDateTime,
  }) async {
    if (forceLooseMatch) {
      return records
          .where((record) => record.scheduledDateTime == scheduledDateTime)
          .firstOrNull;
    }
    return records
        .where(
          (record) =>
              record.medicineId == medicineId &&
              record.scheduledDateTime == scheduledDateTime,
        )
        .firstOrNull;
  }

  @override
  Future<List<IntakeRecord>> getIntakeRecords(String profileId) async =>
      List.of(records);

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
