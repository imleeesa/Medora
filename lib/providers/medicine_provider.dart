import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/intake_record.dart';
import '../models/intake_stock_change.dart';
import '../models/medicine.dart';
import '../models/scheduled_intake.dart';
import '../models/therapy.dart';
import '../models/user_profile.dart';
import '../repositories/intake_repository.dart';
import '../repositories/medicine_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/settings_repository.dart';
import '../repositories/therapy_repository.dart';
import '../services/intake_action_service.dart';
import '../services/missed_intake_planner.dart';
import '../services/notification_action_handler.dart';
import '../services/notification_service.dart';

class MedicineProvider extends ChangeNotifier {
  MedicineProvider({
    ProfileRepository? profileRepository,
    SettingsRepository? settingsRepository,
    TherapyRepository? therapyRepository,
    MedicineRepository? medicineRepository,
    IntakeRepository? intakeRepository,
    MedicineNotificationScheduler? notificationService,
    IntakeActionService? intakeActionService,
  }) : _profileRepository = profileRepository ?? ProfileRepository(),
       _settingsRepository = settingsRepository ?? SettingsRepository(),
       _therapyRepository = therapyRepository ?? TherapyRepository(),
       _medicineRepository = medicineRepository ?? MedicineRepository(),
       _intakeRepository = intakeRepository ?? IntakeRepository(),
       _notificationService = notificationService ?? NotificationService(),
       _intakeActionService =
           intakeActionService ??
           IntakeActionService(
             profileRepository: profileRepository ?? ProfileRepository(),
             medicineRepository: medicineRepository ?? MedicineRepository(),
             intakeRepository: intakeRepository ?? IntakeRepository(),
           );

  final ProfileRepository _profileRepository;
  final SettingsRepository _settingsRepository;
  final TherapyRepository _therapyRepository;
  final MedicineRepository _medicineRepository;
  final IntakeRepository _intakeRepository;
  final MedicineNotificationScheduler _notificationService;
  final IntakeActionService _intakeActionService;
  final List<Therapy> _therapies = [];
  final List<IntakeRecord> _intakeRecords = [];
  StreamSubscription<void>? _notificationActionSubscription;
  UserProfile _currentProfile = UserProfile(
    id: 'local-user',
    name: 'Utente',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  List<Therapy> get therapies => List.unmodifiable(_therapies);

  List<Medicine> get medicines =>
      _therapies.expand((therapy) => therapy.medicines).toList(growable: false);

  List<IntakeRecord> get intakeHistory => List.unmodifiable(_intakeRecords);

  UserProfile get currentProfile => _currentProfile;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    if (_isInitialized || _isLoading) return;

    _listenForNotificationActions();
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _currentProfile = await _loadOrCreateDefaultProfile();
      await _reloadCache();
      await _reloadIntakeHistory();
      await _rolloverMissedIntakes();
      await _initializeNotifications();
      _isInitialized = true;
    } catch (_) {
      _errorMessage = 'Impossibile caricare i dati salvati.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> init() => initialize();

  Future<void> addMedicine({
    required String therapyId,
    required String name,
    required String dose,
    required List<TimeOfDay> times,
    required List<int> daysOfWeek,
    required double stockQuantity,
    required double stockWarningThreshold,
    String? notes,
    String color = '#2E7D32',
    String? icon,
  }) async {
    final therapyIndex = _therapies.indexWhere(
      (therapy) => therapy.id == therapyId,
    );
    if (therapyIndex == -1) {
      throw StateError('La terapia selezionata non e\' disponibile.');
    }
    final now = DateTime.now();
    final therapy = _therapies[therapyIndex];

    final medicine = Medicine(
      id: const Uuid().v4(),
      therapyId: therapy.id,
      name: name.trim(),
      dose: dose.trim(),
      times: List<TimeOfDay>.from(times),
      daysOfWeek: List<int>.from(daysOfWeek)..sort(),
      stockQuantity: stockQuantity,
      stockWarningThreshold: stockWarningThreshold,
      notes: notes?.trim(),
      color: color,
      icon: icon,
      profileId: _currentProfile.id,
      createdAt: now,
      updatedAt: now,
    );

    try {
      if (!therapy.isActive) {
        await _therapyRepository.updateTherapy(
          therapy.copyWith(isActive: true, updatedAt: DateTime.now()),
        );
      }
      await _medicineRepository.createMedicine(medicine);
      await _reloadCache();
      await _scheduleMedicineNotifications(medicine);
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Impossibile salvare la medicina.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addMedicineToTherapy({
    required String therapyId,
    required String name,
    required String dose,
    required List<TimeOfDay> times,
    required List<int> daysOfWeek,
    required double stockQuantity,
    required double stockWarningThreshold,
    String? notes,
    String color = '#2E7D32',
    String? icon,
  }) {
    return addMedicine(
      therapyId: therapyId,
      name: name,
      dose: dose,
      times: times,
      daysOfWeek: daysOfWeek,
      stockQuantity: stockQuantity,
      stockWarningThreshold: stockWarningThreshold,
      notes: notes,
      color: color,
      icon: icon,
    );
  }

  Future<Therapy> createTherapy({
    required String name,
    String? description,
    String color = '#2E7D32',
    int? iconCodePoint,
    DateTime? startDate,
  }) async {
    final cleanedName = name.trim();
    if (cleanedName.isEmpty) {
      throw ArgumentError.value(
        name,
        'name',
        'Il nome della terapia e obbligatorio.',
      );
    }
    final duplicate = _therapies.any(
      (therapy) => therapy.name.toLowerCase() == cleanedName.toLowerCase(),
    );
    if (duplicate) {
      throw StateError('Esiste gia una terapia con questo nome.');
    }

    final now = DateTime.now();
    final cleanedDescription = description?.trim();
    final therapy = Therapy(
      id: const Uuid().v4(),
      profileId: _currentProfile.id,
      name: cleanedName,
      description: cleanedDescription?.isEmpty ?? true
          ? null
          : cleanedDescription,
      color: color,
      iconCodePoint: iconCodePoint,
      startDate: startDate,
      createdAt: now,
      updatedAt: now,
      medicines: const [],
    );

    try {
      await _therapyRepository.createTherapy(therapy);
      await _reloadCache();
      _errorMessage = null;
      notifyListeners();
      return _therapies.firstWhere((item) => item.id == therapy.id);
    } catch (_) {
      _errorMessage = 'Impossibile creare la terapia.';
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> updateTherapy(Therapy therapy) async {
    final currentTherapy = getTherapyById(therapy.id);
    final cleanedName = therapy.name.trim();
    if (cleanedName.isEmpty) {
      throw ArgumentError.value(
        therapy.name,
        'therapy.name',
        'Il nome della terapia e obbligatorio.',
      );
    }
    final duplicate = _therapies.any(
      (item) =>
          item.id != therapy.id &&
          item.name.toLowerCase() == cleanedName.toLowerCase(),
    );
    if (duplicate) {
      throw StateError('Esiste gia una terapia con questo nome.');
    }

    final updatedTherapy = therapy.copyWith(
      name: cleanedName,
      updatedAt: DateTime.now(),
    );
    try {
      final updated = await _therapyRepository.updateTherapy(updatedTherapy);
      if (!updated) return false;
      await _reloadCache();
      if (currentTherapy?.isActive == true && !updatedTherapy.isActive) {
        await _cancelMedicineNotifications(currentTherapy!.medicines);
      } else if (currentTherapy?.isActive == false && updatedTherapy.isActive) {
        await _scheduleTherapyMedicineNotifications(updatedTherapy.id);
      }
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Impossibile aggiornare la terapia.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> archiveTherapy(String therapyId) async {
    final therapy = _therapies
        .where((item) => item.id == therapyId)
        .firstOrNull;
    if (therapy == null) {
      throw StateError('La terapia selezionata non e disponibile.');
    }

    try {
      await _therapyRepository.updateTherapy(
        therapy.copyWith(isActive: false, updatedAt: DateTime.now()),
      );
      await _reloadCache();
      await _cancelMedicineNotifications(therapy.medicines);
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Impossibile aggiornare la terapia.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteTherapy(String therapyId) async {
    final therapy = _therapies
        .where((item) => item.id == therapyId)
        .firstOrNull;
    if (therapy == null) {
      throw StateError('La terapia selezionata non e disponibile.');
    }

    try {
      await _therapyRepository.deleteTherapy(therapy.id);
      await _reloadCache();
      await _reloadIntakeHistory();
      await _cancelMedicineNotifications(therapy.medicines);
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Impossibile eliminare la terapia.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> reactivateTherapy(String therapyId) async {
    final therapy = _therapies
        .where((item) => item.id == therapyId)
        .firstOrNull;
    if (therapy == null) {
      throw StateError('La terapia selezionata non e disponibile.');
    }
    if (therapy.isActive) return;

    try {
      final updated = await _therapyRepository.updateTherapy(
        therapy.copyWith(isActive: true, updatedAt: DateTime.now()),
      );
      if (!updated) return;
      await _reloadCache();
      await _scheduleTherapyMedicineNotifications(therapy.id);
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Impossibile riattivare la terapia.';
      notifyListeners();
      rethrow;
    }
  }

  List<Medicine> getMedicinesByTherapy(String therapyId) {
    return _therapies
        .where((therapy) => therapy.id == therapyId)
        .expand((therapy) => therapy.medicines)
        .toList(growable: false);
  }

  Medicine? getMedicineById(String medicineId) {
    for (final therapy in _therapies) {
      for (final medicine in therapy.medicines) {
        if (medicine.id == medicineId) return medicine;
      }
    }
    return null;
  }

  Therapy? getTherapyById(String therapyId) {
    for (final therapy in _therapies) {
      if (therapy.id == therapyId) return therapy;
    }
    return null;
  }

  Future<void> moveMedicineToTherapy({
    required String medicineId,
    required String targetTherapyId,
  }) async {
    final location = _findMedicine(medicineId);
    if (location == null) {
      throw StateError('La medicina selezionata non e disponibile.');
    }

    final targetTherapy = getTherapyById(targetTherapyId);
    if (targetTherapy == null) {
      throw StateError('La terapia selezionata non e disponibile.');
    }
    if (!targetTherapy.isActive) {
      throw StateError(
        'Non puoi spostare una medicina in una terapia archiviata.',
      );
    }

    final sourceTherapy = _therapies[location.therapyIndex];
    final medicine = sourceTherapy.medicines[location.medicineIndex];
    if (medicine.therapyId == targetTherapyId) return;

    try {
      final updated = await _medicineRepository.updateMedicine(
        medicine.copyWith(
          therapyId: targetTherapyId,
          updatedAt: DateTime.now(),
        ),
      );
      if (!updated) {
        throw StateError('Impossibile aggiornare la terapia della medicina.');
      }
      await _reloadCache();
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Impossibile spostare la medicina.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateMedicine({
    required String id,
    required String name,
    required String dose,
    required List<TimeOfDay> times,
    required List<int> daysOfWeek,
    required double stockQuantity,
    required double stockWarningThreshold,
    String? notes,
    String color = '#2E7D32',
    String? icon,
    required bool isActive,
  }) async {
    final location = _findMedicine(id);
    if (location == null) return;

    final therapy = _therapies[location.therapyIndex];
    final medicine = therapy.medicines[location.medicineIndex];
    final updatedMedicine = medicine.copyWith(
      name: name.trim(),
      dose: dose.trim(),
      times: List<TimeOfDay>.from(times),
      daysOfWeek: List<int>.from(daysOfWeek)..sort(),
      stockQuantity: stockQuantity,
      stockWarningThreshold: stockWarningThreshold,
      notes: notes?.trim(),
      color: color,
      icon: icon,
      isActive: isActive,
      updatedAt: DateTime.now(),
    );
    try {
      final updated = await _medicineRepository.updateMedicine(updatedMedicine);
      if (!updated) return;
      await _reloadCache();
      await _cancelMedicineNotifications([medicine]);
      await _scheduleMedicineNotifications(updatedMedicine);
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Impossibile aggiornare la medicina.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteMedicine(String id) async {
    final location = _findMedicine(id);
    if (location == null) return;
    final medicine =
        _therapies[location.therapyIndex].medicines[location.medicineIndex];

    try {
      await _medicineRepository.deleteMedicine(id);
      await _reloadCache();
      await _reloadIntakeHistory();
      await _cancelMedicineNotifications([medicine]);
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      await _reloadCache();
      await _reloadIntakeHistory();
      _errorMessage = 'Impossibile eliminare la medicina.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleMedicineActive(String id) async {
    final location = _findMedicine(id);
    if (location == null) return;

    final therapy = _therapies[location.therapyIndex];
    final medicine = therapy.medicines[location.medicineIndex];
    final updatedMedicine = medicine.copyWith(
      isActive: !medicine.isActive,
      updatedAt: DateTime.now(),
    );

    try {
      final updated = await _medicineRepository.updateMedicine(updatedMedicine);
      if (!updated) return;
      await _reloadCache();
      if (updatedMedicine.isActive) {
        await _scheduleMedicineNotifications(updatedMedicine);
      } else {
        await _cancelMedicineNotifications([medicine]);
      }
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Impossibile aggiornare lo stato della medicina.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> decrementStock(String id) async {
    final location = _findMedicine(id);
    if (location == null) return;

    final therapy = _therapies[location.therapyIndex];
    final medicine = therapy.medicines[location.medicineIndex];
    if (medicine.stockQuantity <= 0) return;

    final updatedMedicine = medicine.copyWith(
      stockQuantity: medicine.stockQuantity - 1.0,
      updatedAt: DateTime.now(),
    );

    try {
      final updated = await _medicineRepository.updateMedicine(updatedMedicine);
      if (!updated) return;
      await _reloadCache();
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Impossibile aggiornare la scorta.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> addStock({
    required String medicineId,
    required double quantity,
  }) async {
    if (quantity <= 0) {
      throw ArgumentError.value(
        quantity,
        'quantity',
        'La quantita da aggiungere deve essere maggiore di zero.',
      );
    }

    final location = _findMedicine(medicineId);
    if (location == null) {
      throw StateError('La medicina selezionata non e disponibile.');
    }

    final therapy = _therapies[location.therapyIndex];
    final medicine = therapy.medicines[location.medicineIndex];
    final updatedMedicine = medicine.copyWith(
      stockQuantity: medicine.stockQuantity + quantity,
      updatedAt: DateTime.now(),
    );

    try {
      final updated = await _medicineRepository.updateMedicine(updatedMedicine);
      if (!updated) {
        throw StateError('Impossibile aggiornare la scorta della medicina.');
      }
      await _reloadCache();
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Impossibile ricaricare la scorta.';
      notifyListeners();
      rethrow;
    }
  }

  Future<void> updateProfile({
    required String name,
    bool? isDarkMode,
    bool? notificationsEnabled,
  }) async {
    final updatedProfile = _currentProfile.copyWith(
      name: name.trim().isEmpty ? 'Utente' : name.trim(),
      isDarkMode: isDarkMode,
      notificationsEnabled: notificationsEnabled,
      updatedAt: DateTime.now(),
    );
    try {
      final existingSettings = await _settingsRepository.getSettingsForProfile(
        _currentProfile.id,
      );
      final settings =
          (existingSettings ?? _defaultSettings(_currentProfile.id)).copyWith(
            themeMode: (isDarkMode ?? _currentProfile.isDarkMode)
                ? 'dark'
                : 'light',
            notificationsEnabled:
                notificationsEnabled ?? _currentProfile.notificationsEnabled,
            updatedAt: DateTime.now(),
          );
      await _profileRepository.updateProfile(updatedProfile);
      await _settingsRepository.updateSettings(settings);
      _currentProfile = updatedProfile;
      if (notificationsEnabled != null) {
        if (notificationsEnabled) {
          await _rescheduleAllMedicineNotifications();
        } else {
          await _cancelAllMedicineNotifications();
        }
      }
      _errorMessage = null;
      notifyListeners();
    } catch (_) {
      _errorMessage = 'Impossibile aggiornare il profilo.';
      notifyListeners();
      rethrow;
    }
  }

  List<Medicine> getTodayScheduledMedicines() => _therapies
      .where((therapy) => therapy.isActive)
      .expand((therapy) => therapy.medicines)
      .where((medicine) => medicine.shouldTakeToday())
      .toList(growable: false);

  List<IntakeRecord> getIntakeHistory() => intakeHistory;

  List<IntakeRecord> getTodayIntakeRecords() {
    final now = DateTime.now();
    return _intakeRecords
        .where((record) => _isSameDay(record.scheduledDateTime, now))
        .toList(growable: false);
  }

  List<ScheduledIntake> getTodayScheduledIntakes({DateTime? date}) {
    final selectedDate = date ?? DateTime.now();
    final intakes = <ScheduledIntake>[];

    for (final medicine in getTodayScheduledMedicines()) {
      for (final schedule in medicine.schedules) {
        if (!schedule.isActive ||
            !schedule.daysOfWeek.contains(selectedDate.weekday)) {
          continue;
        }

        final scheduledDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          schedule.time.hour,
          schedule.time.minute,
        );
        final record = _findIntakeRecord(medicine.id, scheduledDateTime);
        intakes.add(
          ScheduledIntake(
            medicine: medicine,
            scheduledDateTime: scheduledDateTime,
            record: record,
          ),
        );
      }
    }

    intakes.sort(
      (first, second) =>
          first.scheduledDateTime.compareTo(second.scheduledDateTime),
    );
    return intakes;
  }

  Future<IntakeStockChange> markMedicineAsTaken({
    required String medicineId,
    required DateTime scheduledDateTime,
  }) async {
    return _saveIntakeStatus(
      () => _intakeActionService.markTaken(
        medicineId: medicineId,
        scheduledDateTime: scheduledDateTime,
      ),
    );
  }

  Future<IntakeStockChange> markMedicineAsSkipped({
    required String medicineId,
    required DateTime scheduledDateTime,
  }) async {
    return _saveIntakeStatus(
      () => _intakeActionService.markSkipped(
        medicineId: medicineId,
        scheduledDateTime: scheduledDateTime,
      ),
    );
  }

  List<Medicine> getMedicinesTodayDue() {
    return medicines.where((medicine) => medicine.shouldTakeToday()).toList();
  }

  Medicine? getNextMedicine() {
    final today = getTodayScheduledMedicines()
        .where((medicine) => medicine.getNextIntake() != null)
        .toList();
    if (today.isEmpty) return null;

    today.sort((a, b) {
      final nextA = a.getNextIntake();
      final nextB = b.getNextIntake();
      if (nextA == null || nextB == null) return 0;
      return _compareTimeOfDay(nextA, nextB);
    });

    return today.first;
  }

  List<Medicine> getLowStockMedicines() {
    return medicines
        .where(
          (medicine) =>
              medicine.stockQuantity <= medicine.stockWarningThreshold,
        )
        .toList();
  }

  int _compareTimeOfDay(TimeOfDay first, TimeOfDay second) {
    if (first.hour != second.hour) return first.hour.compareTo(second.hour);
    return first.minute.compareTo(second.minute);
  }

  Future<IntakeStockChange> _saveIntakeStatus(
    Future<IntakeStockChange> Function() action,
  ) async {
    try {
      final stockChange = await action();
      await _reloadCache();
      await _reloadIntakeHistory();
      _errorMessage = null;
      notifyListeners();
      return stockChange;
    } catch (_) {
      _errorMessage = 'Impossibile salvare lo stato dell\'assunzione.';
      notifyListeners();
      rethrow;
    }
  }

  void _listenForNotificationActions() {
    NotificationActionEvents.instance.ensureMainIsolatePort();
    _notificationActionSubscription ??= NotificationActionEvents
        .instance
        .completed
        .listen((_) async {
          try {
            await _reloadCache();
            await _reloadIntakeHistory();
            _errorMessage = null;
            notifyListeners();
          } catch (_) {
            _errorMessage = 'Impossibile aggiornare i dati dopo la notifica.';
            notifyListeners();
          }
        });
  }

  @override
  void dispose() {
    _notificationActionSubscription?.cancel();
    NotificationActionEvents.instance.disposeMainIsolatePort();
    super.dispose();
  }

  IntakeRecord? _findIntakeRecord(
    String medicineId,
    DateTime scheduledDateTime,
  ) {
    for (final record in _intakeRecords) {
      if (record.medicineId == medicineId &&
          record.scheduledDateTime == scheduledDateTime) {
        return record;
      }
    }
    return null;
  }

  bool _isSameDay(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  Future<UserProfile> _loadOrCreateDefaultProfile() async {
    var profile = await _profileRepository.getCurrentProfile();
    if (profile == null) {
      final now = DateTime.now();
      profile = UserProfile(
        id: 'local-user',
        name: 'Utente',
        createdAt: now,
        updatedAt: now,
      );
      await _profileRepository.createProfile(profile);
    }

    final settings = await _settingsRepository.getSettingsForProfile(
      profile.id,
    );
    if (settings == null) {
      await _settingsRepository.updateSettings(_defaultSettings(profile.id));
    }

    return await _profileRepository.getProfileById(profile.id) ?? profile;
  }

  Future<void> _initializeNotifications() async {
    try {
      await _notificationService.initialize();
      await _rescheduleAllMedicineNotifications();
    } catch (_) {
      // I promemoria non devono rendere non disponibile la cache locale.
    }
  }

  Future<void> _rescheduleAllMedicineNotifications() async {
    if (!_currentProfile.notificationsEnabled) return;

    final activeMedicines = _therapies
        .where((therapy) => therapy.isActive)
        .expand((therapy) => therapy.medicines)
        .where((medicine) => medicine.isActive)
        .toList(growable: false);
    try {
      await _notificationService.rescheduleActiveMedicines(activeMedicines);
    } catch (_) {
      // Il salvataggio delle medicine resta valido anche se il sistema nega
      // permessi o non supporta le notifiche locali.
    }
  }

  Future<void> _scheduleMedicineNotifications(Medicine medicine) async {
    if (!_currentProfile.notificationsEnabled || !medicine.isActive) return;

    final therapyId = medicine.therapyId;
    final therapy = therapyId == null ? null : getTherapyById(therapyId);
    if (therapy == null || !therapy.isActive) return;

    try {
      await _notificationService.scheduleMedicineNotifications(medicine);
    } catch (_) {
      // Una mancata pianificazione non deve annullare una modifica persistita.
    }
  }

  Future<void> _scheduleTherapyMedicineNotifications(String therapyId) async {
    final therapy = getTherapyById(therapyId);
    if (therapy == null || !therapy.isActive) return;

    for (final medicine in therapy.medicines) {
      await _scheduleMedicineNotifications(medicine);
    }
  }

  Future<void> _cancelMedicineNotifications(
    Iterable<Medicine> medicines,
  ) async {
    for (final medicine in medicines) {
      try {
        await _notificationService.cancelMedicineNotifications(medicine);
      } catch (_) {
        // La cancellazione dal database non dipende dal canale notifiche.
      }
    }
  }

  Future<void> _cancelAllMedicineNotifications() async {
    try {
      await _notificationService.cancelAllNotifications();
    } catch (_) {
      // Il toggle preferenze deve restare salvabile anche senza supporto OS.
    }
  }

  AppSettings _defaultSettings(String profileId) {
    final now = DateTime.now();
    return AppSettings(
      id: '$profileId-settings',
      profileId: profileId,
      themeMode: 'light',
      notificationsEnabled: true,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> _reloadCache() async {
    final therapies = await _therapyRepository.getTherapies(_currentProfile.id);
    final medicines = await _medicineRepository.getMedicines(
      _currentProfile.id,
    );
    final medicinesByTherapyId = <String, List<Medicine>>{};

    for (final medicine in medicines) {
      final therapyId = medicine.therapyId;
      if (therapyId == null) continue;
      medicinesByTherapyId.putIfAbsent(therapyId, () => []).add(medicine);
    }

    _therapies
      ..clear()
      ..addAll(
        therapies.map(
          (therapy) => therapy.copyWith(
            medicines: medicinesByTherapyId[therapy.id] ?? const [],
          ),
        ),
      );
  }

  Future<void> _reloadIntakeHistory() async {
    final records = await _intakeRepository.getIntakeRecords(
      _currentProfile.id,
    );
    _intakeRecords
      ..clear()
      ..addAll(records);
  }

  Future<void> _rolloverMissedIntakes() async {
    final now = DateTime.now();
    final candidates = MissedIntakePlanner.findCandidates(
      therapies: _therapies,
      records: _intakeRecords,
      referenceDate: now,
    );
    if (candidates.isEmpty) return;

    final records = candidates
        .map(
          (candidate) => IntakeRecord(
            id: const Uuid().v4(),
            medicineId: candidate.medicine.id,
            profileId: _currentProfile.id,
            scheduledDateTime: candidate.scheduledDateTime,
            status: IntakeStatus.missed,
            medicineNameSnapshot: candidate.medicine.name,
            medicineDoseSnapshot: candidate.medicine.dose,
            createdAt: now,
          ),
        )
        .toList(growable: false);
    await _intakeRepository.createIntakeRecords(records);
    await _reloadIntakeHistory();
  }

  _MedicineLocation? _findMedicine(String id) {
    for (
      var therapyIndex = 0;
      therapyIndex < _therapies.length;
      therapyIndex++
    ) {
      final medicineIndex = _therapies[therapyIndex].medicines.indexWhere(
        (medicine) => medicine.id == id,
      );
      if (medicineIndex != -1) {
        return _MedicineLocation(therapyIndex, medicineIndex);
      }
    }
    return null;
  }
}

class _MedicineLocation {
  final int therapyIndex;
  final int medicineIndex;

  const _MedicineLocation(this.therapyIndex, this.medicineIndex);
}
