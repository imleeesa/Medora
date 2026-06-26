import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/models/app_settings.dart';
import 'package:meditrack/models/intake_record.dart';
import 'package:meditrack/models/medicine.dart';
import 'package:meditrack/models/medicine_schedule.dart';
import 'package:meditrack/models/therapy.dart';
import 'package:meditrack/models/user_profile.dart';
import 'package:meditrack/providers/medicine_provider.dart';
import 'package:meditrack/repositories/intake_repository.dart';
import 'package:meditrack/repositories/medicine_repository.dart';
import 'package:meditrack/repositories/profile_repository.dart';
import 'package:meditrack/repositories/settings_repository.dart';
import 'package:meditrack/repositories/therapy_repository.dart';
import 'package:meditrack/services/intake_action_service.dart';
import 'package:meditrack/services/notification_action_handler.dart';
import 'package:meditrack/services/notification_service.dart';

void main() {
  group('MedicineProvider notification scheduling', () {
    test(
      'initializes notifications and reschedules only active medicines',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-active',
              medicines: [
                _medicine(id: 'active-medicine', therapyId: 'therapy-active'),
                _medicine(
                  id: 'inactive-medicine',
                  therapyId: 'therapy-active',
                  isActive: false,
                ),
              ],
            ),
            _therapy(
              id: 'therapy-archived',
              isActive: false,
              medicines: [
                _medicine(
                  id: 'archived-medicine',
                  therapyId: 'therapy-archived',
                ),
              ],
            ),
          ],
        );

        await fixture.provider.initialize();
        await fixture.provider.initialize();

        expect(fixture.notifications.initializeCount, 1);
        expect(fixture.notifications.rescheduledBatches, [
          ['active-medicine'],
        ]);
        expect(fixture.notifications.cancelAllCount, 0);
      },
    );

    test(
      'modifying a medicine cancels the old reminder before scheduling the updated one',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
            ),
          ],
        );
        await fixture.provider.initialize();
        fixture.notifications.clear();

        await fixture.provider.updateMedicine(
          id: 'medicine-1',
          name: 'Aspirina aggiornata',
          dose: '1/2 pastiglia',
          times: const [TimeOfDay(hour: 9, minute: 30)],
          daysOfWeek: const [DateTime.tuesday],
          stockQuantity: 8,
          stockWarningThreshold: 2,
          isActive: true,
        );

        expect(fixture.notifications.cancelledMedicineIds, ['medicine-1']);
        expect(fixture.notifications.scheduledMedicineIds, ['medicine-1']);
        expect(
          fixture.medicineRepository.medicines['medicine-1']?.dose,
          '1/2 pastiglia',
        );
      },
    );

    test(
      'deleting and deactivating medicines cancel reminders, reactivation schedules them again',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(id: 'medicine-delete', therapyId: 'therapy-1'),
                _medicine(id: 'medicine-toggle', therapyId: 'therapy-1'),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();
        fixture.notifications.clear();

        await fixture.provider.deleteMedicine('medicine-delete');
        expect(fixture.notifications.cancelledMedicineIds, ['medicine-delete']);

        fixture.notifications.clear();
        await fixture.provider.toggleMedicineActive('medicine-toggle');
        expect(fixture.notifications.cancelledMedicineIds, ['medicine-toggle']);
        expect(fixture.notifications.scheduledMedicineIds, isEmpty);

        fixture.notifications.clear();
        await fixture.provider.toggleMedicineActive('medicine-toggle');
        expect(fixture.notifications.scheduledMedicineIds, ['medicine-toggle']);
        expect(fixture.notifications.cancelledMedicineIds, isEmpty);
      },
    );

    test(
      'archiving, reactivating and deleting therapies update reminders safely',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(id: 'medicine-1', therapyId: 'therapy-1'),
                _medicine(id: 'medicine-2', therapyId: 'therapy-1'),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();
        fixture.notifications.clear();

        await fixture.provider.archiveTherapy('therapy-1');
        expect(fixture.notifications.cancelledMedicineIds, [
          'medicine-1',
          'medicine-2',
        ]);

        fixture.notifications.clear();
        await fixture.provider.reactivateTherapy('therapy-1');
        expect(fixture.notifications.scheduledMedicineIds, [
          'medicine-1',
          'medicine-2',
        ]);

        fixture.notifications.clear();
        await fixture.provider.deleteTherapy('therapy-1');
        expect(fixture.notifications.cancelledMedicineIds, [
          'medicine-1',
          'medicine-2',
        ]);
      },
    );

    test(
      'profile notification toggle cancels all reminders or reschedules active ones',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
            ),
          ],
        );
        await fixture.provider.initialize();
        fixture.notifications.clear();

        await fixture.provider.updateProfile(
          name: 'Utente',
          notificationsEnabled: false,
        );
        expect(fixture.notifications.cancelAllCount, 1);
        expect(fixture.notifications.rescheduledBatches, isEmpty);

        fixture.notifications.clear();
        await fixture.provider.updateProfile(
          name: 'Utente',
          notificationsEnabled: true,
        );
        expect(fixture.notifications.cancelAllCount, 0);
        expect(fixture.notifications.rescheduledBatches, [
          ['medicine-1'],
        ]);
      },
    );

    test(
      'notification permission failures do not block saved medicine changes',
      () async {
        final fixture = _ProviderFixture(
          therapies: [_therapy(id: 'therapy-1')],
          notifications: _FakeNotificationScheduler(throwOnSchedule: true),
        );
        await fixture.provider.initialize();

        await fixture.provider.addMedicine(
          therapyId: 'therapy-1',
          name: 'Vitamina D',
          dose: '1 compressa',
          times: const [TimeOfDay(hour: 8, minute: 0)],
          daysOfWeek: const [DateTime.monday],
          stockQuantity: 10,
          stockWarningThreshold: 2,
        );

        expect(fixture.provider.errorMessage, isNull);
        expect(
          fixture.provider.getMedicineById(fixture.createdMedicineId),
          isNotNull,
        );
        expect(fixture.notifications.scheduledMedicineIds, isEmpty);
      },
    );

    test(
      'notification initialization failures do not block provider startup',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
            ),
          ],
          notifications: _FakeNotificationScheduler(throwOnInitialize: true),
        );

        await fixture.provider.initialize();

        expect(fixture.provider.errorMessage, isNull);
        expect(fixture.provider.medicines, hasLength(1));
      },
    );

    test(
      'exact alarm or permission denial during reschedule is best effort',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [_medicine(id: 'medicine-1', therapyId: 'therapy-1')],
            ),
          ],
          notifications: _FakeNotificationScheduler(throwOnReschedule: true),
        );

        await fixture.provider.initialize();

        expect(fixture.provider.errorMessage, isNull);
        expect(fixture.provider.medicines, hasLength(1));
      },
    );

    test(
      'external notification action reloads provider history and stock without restart',
      () async {
        final fixture = _ProviderFixture(
          therapies: [
            _therapy(
              id: 'therapy-1',
              medicines: [
                _medicine(
                  id: 'medicine-1',
                  therapyId: 'therapy-1',
                  dose: '1/2 pastiglia',
                ),
              ],
            ),
          ],
        );
        await fixture.provider.initialize();

        final handler = NotificationActionHandler(
          intakeActionService: IntakeActionService(
            profileRepository: fixture.profileRepository,
            medicineRepository: fixture.medicineRepository,
            intakeRepository: fixture.intakeRepository,
            therapyRepository: fixture.therapyRepository,
          ),
        );

        final handled = await handler.handle(
          actionId: NotificationActionIds.taken,
          payload: NotificationService.payloadFor(
            medicineId: 'medicine-1',
            dayOfWeek: DateTime.monday,
            hour: 8,
            minute: 0,
          ),
          referenceDate: DateTime(2026, 6, 22, 8, 5),
        );
        await _waitFor(
          () =>
              fixture.provider.intakeHistory.isNotEmpty &&
              fixture.provider.getMedicineById('medicine-1')?.stockQuantity ==
                  9.5,
        );

        expect(handled, isTrue);
        expect(fixture.provider.intakeHistory, hasLength(1));
        expect(
          fixture.provider.intakeHistory.single.status,
          IntakeStatus.taken,
        );
        expect(
          fixture.provider.getMedicineById('medicine-1')?.stockQuantity,
          9.5,
        );
      },
    );
  });
}

class _ProviderFixture {
  _ProviderFixture({
    required List<Therapy> therapies,
    _FakeNotificationScheduler? notifications,
    bool notificationsEnabled = true,
  }) : notifications = notifications ?? _FakeNotificationScheduler(),
       profileRepository = _FakeProfileRepository(
         _profile(notificationsEnabled: notificationsEnabled),
       ),
       settingsRepository = _FakeSettingsRepository(
         _settings(notificationsEnabled: notificationsEnabled),
       ),
       therapyRepository = _FakeTherapyRepository(therapies),
       medicineRepository = _FakeMedicineRepository.fromTherapies(therapies),
       intakeRepository = _FakeIntakeRepository() {
    intakeRepository.onUpdateMedicine = (medicine) {
      medicineRepository.medicines[medicine.id] = medicine;
    };
    provider = MedicineProvider(
      profileRepository: profileRepository,
      settingsRepository: settingsRepository,
      therapyRepository: therapyRepository,
      medicineRepository: medicineRepository,
      intakeRepository: intakeRepository,
      notificationService: this.notifications,
    );
  }

  final _FakeProfileRepository profileRepository;
  final _FakeSettingsRepository settingsRepository;
  final _FakeTherapyRepository therapyRepository;
  final _FakeMedicineRepository medicineRepository;
  final _FakeIntakeRepository intakeRepository;
  final _FakeNotificationScheduler notifications;
  late final MedicineProvider provider;

  String get createdMedicineId => medicineRepository.medicines.keys.firstWhere(
    (id) => id != 'medicine-1' && id != 'medicine-2',
    orElse: () => medicineRepository.medicines.keys.last,
  );
}

class _FakeNotificationScheduler implements MedicineNotificationScheduler {
  _FakeNotificationScheduler({
    this.throwOnInitialize = false,
    this.throwOnSchedule = false,
    this.throwOnReschedule = false,
  });

  final bool throwOnInitialize;
  final bool throwOnSchedule;
  final bool throwOnReschedule;
  int initializeCount = 0;
  int cancelAllCount = 0;
  final scheduledMedicineIds = <String>[];
  final cancelledMedicineIds = <String>[];
  final rescheduledBatches = <List<String>>[];

  @override
  Future<void> initialize() async {
    initializeCount++;
    if (throwOnInitialize) throw StateError('Notifications unavailable');
  }

  @override
  Future<void> rescheduleActiveMedicines(Iterable<Medicine> medicines) async {
    if (throwOnReschedule) throw StateError('Permission denied');
    rescheduledBatches.add(
      medicines.map((medicine) => medicine.id).toList(growable: false),
    );
  }

  @override
  Future<void> scheduleMedicineNotifications(Medicine medicine) async {
    if (throwOnSchedule) throw StateError('Permission denied');
    scheduledMedicineIds.add(medicine.id);
  }

  @override
  Future<void> cancelMedicineNotifications(Medicine medicine) async {
    cancelledMedicineIds.add(medicine.id);
  }

  @override
  Future<void> cancelAllNotifications() async {
    cancelAllCount++;
  }

  void clear() {
    cancelAllCount = 0;
    scheduledMedicineIds.clear();
    cancelledMedicineIds.clear();
    rescheduledBatches.clear();
  }
}

class _FakeProfileRepository implements ProfileRepository {
  _FakeProfileRepository(this.profile);

  UserProfile profile;

  @override
  Future<void> createProfile(UserProfile profile) async {
    this.profile = profile;
  }

  @override
  Future<UserProfile?> getCurrentProfile() async => profile;

  @override
  Future<UserProfile?> getProfileById(String profileId) async =>
      profile.id == profileId ? profile : null;

  @override
  Future<bool> updateProfile(UserProfile profile) async {
    this.profile = profile;
    return true;
  }
}

class _FakeSettingsRepository implements SettingsRepository {
  _FakeSettingsRepository(this.settings);

  AppSettings settings;

  @override
  Future<AppSettings?> getSettingsForProfile(String profileId) async =>
      settings.profileId == profileId ? settings : null;

  @override
  Future<void> updateSettings(AppSettings settings) async {
    this.settings = settings;
  }
}

class _FakeTherapyRepository implements TherapyRepository {
  _FakeTherapyRepository(List<Therapy> therapies)
    : therapies = {
        for (final therapy in therapies)
          therapy.id: therapy.copyWith(medicines: const []),
      };

  final Map<String, Therapy> therapies;

  @override
  Future<void> createTherapy(Therapy therapy) async {
    therapies[therapy.id] = therapy.copyWith(medicines: const []);
  }

  @override
  Future<void> createTherapyWithMedicine(
    Therapy therapy,
    Medicine medicine,
  ) async {
    therapies[therapy.id] = therapy.copyWith(medicines: const []);
  }

  @override
  Future<void> deleteTherapy(String therapyId) async {
    therapies.remove(therapyId);
  }

  @override
  Future<List<Therapy>> getTherapies(String profileId) async =>
      therapies.values.toList(growable: false);

  @override
  Future<bool> updateTherapy(Therapy therapy) async {
    if (!therapies.containsKey(therapy.id)) return false;
    therapies[therapy.id] = therapy.copyWith(medicines: const []);
    return true;
  }

  @override
  Stream<List<Therapy>> watchTherapies(String profileId) =>
      Stream.value(therapies.values.toList(growable: false));
}

class _FakeMedicineRepository implements MedicineRepository {
  _FakeMedicineRepository.fromTherapies(List<Therapy> therapies)
    : medicines = {
        for (final therapy in therapies)
          for (final medicine in therapy.medicines) medicine.id: medicine,
      };

  final Map<String, Medicine> medicines;

  @override
  Future<void> createMedicine(Medicine medicine) async {
    medicines[medicine.id] = medicine;
  }

  @override
  Future<void> deleteMedicine(String medicineId) async {
    medicines.remove(medicineId);
  }

  @override
  Future<List<Medicine>> getLowStockMedicines(String profileId) async =>
      (await getMedicines(profileId))
          .where(
            (medicine) =>
                medicine.stockQuantity <= medicine.stockWarningThreshold,
          )
          .toList(growable: false);

  @override
  Future<List<Medicine>> getMedicines(String profileId) async => medicines
      .values
      .where((medicine) => medicine.profileId == profileId)
      .toList(growable: false);

  @override
  Future<List<Medicine>> getMedicinesByTherapy(String therapyId) async =>
      medicines.values
          .where((medicine) => medicine.therapyId == therapyId)
          .toList(growable: false);

  @override
  Future<List<MedicineSchedule>> getSchedulesForMedicine(
    String medicineId,
  ) async => medicines[medicineId]?.schedules ?? const [];

  @override
  Future<void> replaceSchedules(
    String medicineId,
    List<MedicineSchedule> schedules,
  ) async {
    final medicine = medicines[medicineId];
    if (medicine != null) {
      medicines[medicineId] = medicine.copyWith(schedules: schedules);
    }
  }

  @override
  Future<bool> updateMedicine(Medicine medicine) async {
    if (!medicines.containsKey(medicine.id)) return false;
    medicines[medicine.id] = medicine;
    return true;
  }

  @override
  Stream<List<Medicine>> watchMedicines(String profileId) =>
      Stream.value(medicines.values.toList(growable: false));
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
  Future<List<IntakeRecord>> getIntakeRecords(String profileId) async => records
      .where((record) => record.profileId == profileId)
      .toList(growable: false);

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
      if (index == -1) throw StateError('Record not found');
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

Therapy _therapy({
  required String id,
  List<Medicine> medicines = const [],
  bool isActive = true,
}) {
  final now = DateTime.now();
  return Therapy(
    id: id,
    profileId: 'profile-1',
    name: id,
    color: '#2E7D32',
    isActive: isActive,
    medicines: medicines,
    createdAt: now,
    updatedAt: now,
  );
}

Medicine _medicine({
  required String id,
  required String therapyId,
  String dose = '1 compressa',
  bool isActive = true,
}) {
  final now = DateTime.now();
  return Medicine(
    id: id,
    profileId: 'profile-1',
    therapyId: therapyId,
    name: id,
    dose: dose,
    times: const [TimeOfDay(hour: 8, minute: 0)],
    daysOfWeek: const [DateTime.monday],
    stockQuantity: 10,
    stockWarningThreshold: 2,
    isActive: isActive,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _waitFor(
  bool Function() predicate, {
  Duration timeout = const Duration(seconds: 1),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!predicate()) {
    if (DateTime.now().isAfter(deadline)) {
      throw StateError('Condition not reached before timeout.');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

UserProfile _profile({required bool notificationsEnabled}) {
  final now = DateTime.now();
  return UserProfile(
    id: 'profile-1',
    name: 'Utente',
    notificationsEnabled: notificationsEnabled,
    createdAt: now,
    updatedAt: now,
  );
}

AppSettings _settings({required bool notificationsEnabled}) {
  final now = DateTime.now();
  return AppSettings(
    id: 'profile-1-settings',
    profileId: 'profile-1',
    themeMode: 'light',
    notificationsEnabled: notificationsEnabled,
    createdAt: now,
    updatedAt: now,
  );
}
