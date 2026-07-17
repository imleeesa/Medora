import 'package:uuid/uuid.dart';

import '../models/intake_record.dart';
import '../models/intake_stock_change.dart';
import '../models/medicine.dart';
import '../repositories/intake_repository.dart';
import '../repositories/medicine_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/therapy_repository.dart';
import 'medicine_notification_scheduler.dart';

class IntakeActionService {
  IntakeActionService({
    ProfileRepository? profileRepository,
    MedicineRepository? medicineRepository,
    IntakeRepository? intakeRepository,
    TherapyRepository? therapyRepository,
    MedicineNotificationScheduler? notificationService,
  }) : _profileRepository = profileRepository ?? ProfileRepository(),
       _medicineRepository = medicineRepository ?? MedicineRepository(),
       _intakeRepository = intakeRepository ?? IntakeRepository(),
       _therapyRepository = therapyRepository ?? TherapyRepository(),
       _notificationService = notificationService;

  final ProfileRepository _profileRepository;
  final MedicineRepository _medicineRepository;
  final IntakeRepository _intakeRepository;
  final TherapyRepository _therapyRepository;
  final MedicineNotificationScheduler? _notificationService;

  Future<IntakeStockChange> markTaken({
    required String medicineId,
    required DateTime scheduledDateTime,
  }) {
    return saveIntakeStatus(
      medicineId: medicineId,
      scheduledDateTime: scheduledDateTime,
      status: IntakeStatus.taken,
    );
  }

  Future<IntakeStockChange> markSkipped({
    required String medicineId,
    required DateTime scheduledDateTime,
  }) {
    return saveIntakeStatus(
      medicineId: medicineId,
      scheduledDateTime: scheduledDateTime,
      status: IntakeStatus.skipped,
    );
  }

  Future<IntakeStockChange> markTakenFromNotification({
    required String medicineId,
    required DateTime scheduledDateTime,
    required int dayOfWeek,
    required int hour,
    required int minute,
    DateTime? referenceDate,
  }) {
    return saveIntakeStatus(
      medicineId: medicineId,
      scheduledDateTime: scheduledDateTime,
      status: IntakeStatus.taken,
      notificationSlot: NotificationIntakeSlot(
        dayOfWeek: dayOfWeek,
        hour: hour,
        minute: minute,
        referenceDate: referenceDate,
      ),
    );
  }

  Future<IntakeStockChange> markSkippedFromNotification({
    required String medicineId,
    required DateTime scheduledDateTime,
    required int dayOfWeek,
    required int hour,
    required int minute,
    DateTime? referenceDate,
  }) {
    return saveIntakeStatus(
      medicineId: medicineId,
      scheduledDateTime: scheduledDateTime,
      status: IntakeStatus.skipped,
      notificationSlot: NotificationIntakeSlot(
        dayOfWeek: dayOfWeek,
        hour: hour,
        minute: minute,
        referenceDate: referenceDate,
      ),
    );
  }

  Future<IntakeStockChange> saveIntakeStatus({
    required String medicineId,
    required DateTime scheduledDateTime,
    required IntakeStatus status,
    NotificationIntakeSlot? notificationSlot,
  }) async {
    final profile = await _profileRepository.getCurrentProfile();
    if (profile == null) {
      throw StateError('Profilo locale non disponibile.');
    }

    final medicines = await _medicineRepository.getMedicines(profile.id);
    final medicine = medicines
        .where((medicine) => medicine.id == medicineId)
        .firstOrNull;
    if (medicine == null) {
      throw StateError('La medicina selezionata non e disponibile.');
    }
    if (notificationSlot != null) {
      final isAllowed = await _isNotificationSlotAllowed(
        profileId: profile.id,
        medicine: medicine,
        scheduledDateTime: scheduledDateTime,
        slot: notificationSlot,
      );
      if (!isAllowed) {
        return IntakeStockChange.unchanged;
      }
    }

    final existingRecord = await _intakeRepository.getIntakeRecordForSchedule(
      medicineId: medicineId,
      scheduledDateTime: scheduledDateTime,
    );
    // Difesa in profondita': un'azione Assunta/Saltata puo' aggiornare solo
    // un record che appartiene esattamente alla medicina selezionata.
    // I record di medicine eliminate hanno medicineId null e non devono mai
    // essere riusati da nuove azioni, anche se condividono data e orario.
    if (existingRecord != null && existingRecord.medicineId != medicineId) {
      throw StateError(
        'Il record storico trovato non appartiene alla medicina selezionata.',
      );
    }
    final now = DateTime.now();
    final wasTaken = existingRecord?.status == IntakeStatus.taken;
    final isTaken = status == IntakeStatus.taken;
    final shouldDecreaseStock = !wasTaken && isTaken;
    final shouldRestoreStock = wasTaken && status == IntakeStatus.skipped;
    final stockAmount = shouldRestoreStock
        ? Medicine.stockConsumptionAmountFromDose(
            existingRecord!.medicineDoseSnapshot,
          )
        : medicine.stockConsumptionAmount;

    Medicine? updatedMedicine;
    var stockChange = IntakeStockChange.unchanged;
    if (shouldDecreaseStock) {
      if (stockAmount == null) {
        stockChange = IntakeStockChange.noQuantity;
      } else {
        if (medicine.stockQuantity + 0.000001 < stockAmount) {
          throw StateError(
            'Scorta insufficiente per registrare questa assunzione.',
          );
        }
        updatedMedicine = medicine.copyWith(
          stockQuantity: Medicine.normalizeQuantity(
            medicine.stockQuantity - stockAmount,
          ),
          updatedAt: now,
        );
        stockChange = IntakeStockChange.decreased;
      }
    } else if (shouldRestoreStock) {
      if (stockAmount == null) {
        stockChange = IntakeStockChange.noQuantity;
      } else {
        updatedMedicine = medicine.copyWith(
          stockQuantity: Medicine.normalizeQuantity(
            medicine.stockQuantity + stockAmount,
          ),
          updatedAt: now,
        );
        stockChange = IntakeStockChange.restored;
      }
    }

    final preserveTakenSnapshot = shouldRestoreStock;
    final record = existingRecord == null
        ? IntakeRecord(
            id: const Uuid().v4(),
            medicineId: medicine.id,
            profileId: profile.id,
            scheduledDateTime: scheduledDateTime,
            actualDateTime: status == IntakeStatus.taken ? now : null,
            status: status,
            medicineNameSnapshot: medicine.name,
            medicineDoseSnapshot: medicine.dose,
            createdAt: now,
          )
        : existingRecord.copyWith(
            status: status,
            actualDateTime: status == IntakeStatus.taken ? now : null,
            clearActualDateTime: status == IntakeStatus.skipped,
            medicineNameSnapshot: preserveTakenSnapshot
                ? existingRecord.medicineNameSnapshot
                : medicine.name,
            medicineDoseSnapshot: preserveTakenSnapshot
                ? existingRecord.medicineDoseSnapshot
                : medicine.dose,
          );

    await _intakeRepository.saveIntakeRecordWithStock(
      record: record,
      updateExistingRecord: existingRecord != null,
      updatedMedicine: updatedMedicine,
    );
    await _notifyLowStockIfCrossedThreshold(
      profileId: profile.id,
      notificationsEnabled: profile.notificationsEnabled,
      previous: medicine,
      current: updatedMedicine,
    );
    return stockChange;
  }

  Future<void> _notifyLowStockIfCrossedThreshold({
    required String profileId,
    required bool notificationsEnabled,
    required Medicine previous,
    required Medicine? current,
  }) async {
    if (!notificationsEnabled || current == null) return;
    if (!_crossedLowStockThreshold(previous, current)) return;

    final isActiveTherapy = await _isMedicineInActiveTherapy(
      profileId: profileId,
      medicine: current,
    );
    if (!isActiveTherapy) return;

    try {
      await _notificationService?.showLowStockNotification(current);
    } catch (_) {
      // La registrazione dell'assunzione non deve dipendere dalle notifiche.
    }
  }

  bool _crossedLowStockThreshold(Medicine previous, Medicine current) {
    final threshold = current.stockWarningThreshold;
    return current.isActive &&
        threshold > 0 &&
        previous.stockQuantity > threshold &&
        current.stockQuantity <= threshold;
  }

  Future<bool> _isNotificationSlotAllowed({
    required String profileId,
    required Medicine medicine,
    required DateTime scheduledDateTime,
    required NotificationIntakeSlot slot,
  }) async {
    if (!medicine.isActive) return false;
    if (!_isTodayOrYesterday(scheduledDateTime, slot.referenceDate)) {
      return false;
    }
    if (!_isScheduleStillCompatible(medicine, slot)) return false;

    final therapyId = medicine.therapyId;
    if (therapyId == null) return false;
    final therapies = await _therapyRepository.getTherapies(profileId);
    final therapy = therapies
        .where((therapy) => therapy.id == therapyId)
        .firstOrNull;
    return therapy?.isActive ?? false;
  }

  Future<bool> _isMedicineInActiveTherapy({
    required String profileId,
    required Medicine medicine,
  }) async {
    final therapyId = medicine.therapyId;
    if (therapyId == null) return false;
    final therapies = await _therapyRepository.getTherapies(profileId);
    final therapy = therapies
        .where((therapy) => therapy.id == therapyId)
        .firstOrNull;
    return therapy?.isActive ?? false;
  }

  bool _isTodayOrYesterday(DateTime scheduledDateTime, DateTime referenceDate) {
    final slotDay = DateTime(
      scheduledDateTime.year,
      scheduledDateTime.month,
      scheduledDateTime.day,
    );
    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final yesterday = today.subtract(const Duration(days: 1));
    return slotDay == today || slotDay == yesterday;
  }

  bool _isScheduleStillCompatible(
    Medicine medicine,
    NotificationIntakeSlot slot,
  ) {
    return medicine.schedules.any(
      (schedule) =>
          schedule.isActive &&
          schedule.time.hour == slot.hour &&
          schedule.time.minute == slot.minute &&
          schedule.daysOfWeek.contains(slot.dayOfWeek),
    );
  }
}

class NotificationIntakeSlot {
  NotificationIntakeSlot({
    required this.dayOfWeek,
    required this.hour,
    required this.minute,
    DateTime? referenceDate,
  }) : referenceDate = referenceDate ?? DateTime.now();

  final int dayOfWeek;
  final int hour;
  final int minute;
  final DateTime referenceDate;
}
