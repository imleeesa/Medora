import 'package:uuid/uuid.dart';

import '../models/intake_record.dart';
import '../models/intake_stock_change.dart';
import '../models/medicine.dart';
import '../repositories/intake_repository.dart';
import '../repositories/medicine_repository.dart';
import '../repositories/profile_repository.dart';
import '../repositories/therapy_repository.dart';

class IntakeActionService {
  IntakeActionService({
    ProfileRepository? profileRepository,
    MedicineRepository? medicineRepository,
    IntakeRepository? intakeRepository,
    TherapyRepository? therapyRepository,
  }) : _profileRepository = profileRepository ?? ProfileRepository(),
       _medicineRepository = medicineRepository ?? MedicineRepository(),
       _intakeRepository = intakeRepository ?? IntakeRepository(),
       _therapyRepository = therapyRepository ?? TherapyRepository();

  final ProfileRepository _profileRepository;
  final MedicineRepository _medicineRepository;
  final IntakeRepository _intakeRepository;
  final TherapyRepository _therapyRepository;

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
    return stockChange;
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
