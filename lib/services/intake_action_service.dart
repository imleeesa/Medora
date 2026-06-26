import 'package:uuid/uuid.dart';

import '../models/intake_record.dart';
import '../models/intake_stock_change.dart';
import '../models/medicine.dart';
import '../repositories/intake_repository.dart';
import '../repositories/medicine_repository.dart';
import '../repositories/profile_repository.dart';

class IntakeActionService {
  IntakeActionService({
    ProfileRepository? profileRepository,
    MedicineRepository? medicineRepository,
    IntakeRepository? intakeRepository,
  }) : _profileRepository = profileRepository ?? ProfileRepository(),
       _medicineRepository = medicineRepository ?? MedicineRepository(),
       _intakeRepository = intakeRepository ?? IntakeRepository();

  final ProfileRepository _profileRepository;
  final MedicineRepository _medicineRepository;
  final IntakeRepository _intakeRepository;

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

  Future<IntakeStockChange> saveIntakeStatus({
    required String medicineId,
    required DateTime scheduledDateTime,
    required IntakeStatus status,
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
}
