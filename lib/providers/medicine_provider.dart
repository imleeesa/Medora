import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/medicine.dart';
import '../models/therapy.dart';
import '../models/user_profile.dart';

class MedicineProvider extends ChangeNotifier {
  final List<Therapy> _therapies = [];
  UserProfile _currentProfile = UserProfile(
    id: 'local-user',
    name: 'Utente',
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
  bool _isLoading = false;

  List<Therapy> get therapies => List.unmodifiable(_therapies);

  List<Medicine> get medicines => _therapies
      .expand((therapy) => therapy.medicines)
      .toList(growable: false);

  UserProfile get currentProfile => _currentProfile;

  bool get isLoading => _isLoading;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addMedicine({
    required String name,
    required String dose,
    required List<TimeOfDay> times,
    required List<int> daysOfWeek,
    required int stockQuantity,
    required int stockWarningThreshold,
    String? notes,
    String color = '#2E7D32',
    String? icon,
    String therapyName = 'Terapia generale',
  }) async {
    final cleanedTherapyName = therapyName.trim().isEmpty
        ? 'Terapia generale'
        : therapyName.trim();
    final therapyIndex = _therapies.indexWhere(
      (therapy) =>
          therapy.name.toLowerCase() == cleanedTherapyName.toLowerCase(),
    );
    final therapyId = therapyIndex == -1
        ? const Uuid().v4()
        : _therapies[therapyIndex].id;

    final medicine = Medicine(
      id: const Uuid().v4(),
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    if (therapyIndex == -1) {
      _therapies.add(
        Therapy(
          id: therapyId,
          name: cleanedTherapyName,
          color: color,
          medicines: [medicine],
        ),
      );
    } else {
      final therapy = _therapies[therapyIndex];
      _therapies[therapyIndex] = therapy.copyWith(
        medicines: [...therapy.medicines, medicine],
      );
    }

    notifyListeners();
  }

  Future<void> updateMedicine({
    required String id,
    required String name,
    required String dose,
    required List<TimeOfDay> times,
    required List<int> daysOfWeek,
    required int stockQuantity,
    required int stockWarningThreshold,
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
    final updatedMedicines = [...therapy.medicines];
    updatedMedicines[location.medicineIndex] = updatedMedicine;
    _therapies[location.therapyIndex] = therapy.copyWith(
      medicines: updatedMedicines,
    );

    notifyListeners();
  }

  Future<void> deleteMedicine(String id) async {
    final location = _findMedicine(id);
    if (location == null) return;

    final therapy = _therapies[location.therapyIndex];
    final updatedMedicines = [...therapy.medicines]
      ..removeAt(location.medicineIndex);

    if (updatedMedicines.isEmpty) {
      _therapies.removeAt(location.therapyIndex);
    } else {
      _therapies[location.therapyIndex] = therapy.copyWith(
        medicines: updatedMedicines,
      );
    }

    notifyListeners();
  }

  Future<void> toggleMedicineActive(String id) async {
    final location = _findMedicine(id);
    if (location == null) return;

    final therapy = _therapies[location.therapyIndex];
    final medicine = therapy.medicines[location.medicineIndex];
    final updatedMedicines = [...therapy.medicines];
    updatedMedicines[location.medicineIndex] = medicine.copyWith(
      isActive: !medicine.isActive,
      updatedAt: DateTime.now(),
    );
    _therapies[location.therapyIndex] = therapy.copyWith(
      medicines: updatedMedicines,
    );

    notifyListeners();
  }

  Future<void> decrementStock(String id) async {
    final location = _findMedicine(id);
    if (location == null) return;

    final therapy = _therapies[location.therapyIndex];
    final medicine = therapy.medicines[location.medicineIndex];
    if (medicine.stockQuantity <= 0) return;

    final updatedMedicines = [...therapy.medicines];
    updatedMedicines[location.medicineIndex] = medicine.copyWith(
      stockQuantity: medicine.stockQuantity - 1,
      updatedAt: DateTime.now(),
    );
    _therapies[location.therapyIndex] = therapy.copyWith(
      medicines: updatedMedicines,
    );

    notifyListeners();
  }

  Future<void> updateProfile({
    required String name,
    bool? isDarkMode,
    bool? notificationsEnabled,
  }) async {
    _currentProfile = _currentProfile.copyWith(
      name: name.trim().isEmpty ? 'Utente' : name.trim(),
      isDarkMode: isDarkMode,
      notificationsEnabled: notificationsEnabled,
      updatedAt: DateTime.now(),
    );
    notifyListeners();
  }

  List<Medicine> getMedicinesTodayDue() {
    return medicines.where((medicine) => medicine.shouldTakeToday()).toList();
  }

  Medicine? getNextMedicine() {
    final today = getMedicinesTodayDue()
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

  _MedicineLocation? _findMedicine(String id) {
    for (var therapyIndex = 0; therapyIndex < _therapies.length; therapyIndex++) {
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
