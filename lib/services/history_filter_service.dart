import '../models/intake_record.dart';
import '../models/medicine.dart';
import '../models/therapy.dart';

enum HistoryStatusFilter { all, taken, skipped, missed }

enum HistoryPeriodFilter { today, last7Days, last30Days, all }

class HistoryFilters {
  final HistoryStatusFilter status;
  final HistoryPeriodFilter period;
  final String? therapyId;
  final String? medicineId;
  final String? medicineSnapshotName;

  const HistoryFilters({
    this.status = HistoryStatusFilter.all,
    this.period = HistoryPeriodFilter.all,
    this.therapyId,
    this.medicineId,
    this.medicineSnapshotName,
  });

  bool get hasActiveFilters =>
      status != HistoryStatusFilter.all ||
      period != HistoryPeriodFilter.all ||
      therapyId != null ||
      medicineId != null ||
      medicineSnapshotName != null;
}

class HistoryMedicineFilterOption {
  final String value;
  final String label;
  final String? medicineId;
  final String? snapshotName;

  const HistoryMedicineFilterOption({
    required this.value,
    required this.label,
    this.medicineId,
    this.snapshotName,
  });
}

class HistoryFilterService {
  const HistoryFilterService._();

  static List<IntakeRecord> filterRecords({
    required Iterable<IntakeRecord> records,
    required Iterable<Therapy> therapies,
    required HistoryFilters filters,
    required DateTime referenceDate,
  }) {
    final medicineById = _medicineById(therapies);
    final filtered = records
        .where((record) {
          return _matchesStatus(record, filters.status) &&
              _matchesPeriod(record, filters.period, referenceDate) &&
              _matchesTherapy(record, filters.therapyId, medicineById) &&
              _matchesMedicine(
                record,
                filters.medicineId,
                filters.medicineSnapshotName,
                medicineById,
              );
        })
        .toList(growable: false);

    filtered.sort(
      (first, second) =>
          second.scheduledDateTime.compareTo(first.scheduledDateTime),
    );
    return filtered;
  }

  static List<HistoryMedicineFilterOption> buildMedicineOptions({
    required Iterable<IntakeRecord> records,
    required Iterable<Therapy> therapies,
  }) {
    final medicines = _medicineById(therapies).values.toList()
      ..sort(
        (first, second) =>
            first.name.toLowerCase().compareTo(second.name.toLowerCase()),
      );
    final options = <HistoryMedicineFilterOption>[
      for (final medicine in medicines)
        HistoryMedicineFilterOption(
          value: 'medicine:${medicine.id}',
          label: medicine.name,
          medicineId: medicine.id,
        ),
    ];

    final currentMedicineIds = medicines.map((medicine) => medicine.id).toSet();
    final deletedSnapshots = <String, String>{};
    for (final record in records) {
      final medicineId = record.medicineId;
      final snapshot = record.medicineNameSnapshot.trim();
      if (snapshot.isEmpty) continue;
      if (medicineId != null && currentMedicineIds.contains(medicineId)) {
        continue;
      }
      deletedSnapshots.putIfAbsent(_normalize(snapshot), () => snapshot);
    }

    final deletedNames = deletedSnapshots.values.toList()
      ..sort(
        (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
      );
    for (final name in deletedNames) {
      options.add(
        HistoryMedicineFilterOption(
          value: 'snapshot:${_normalize(name)}',
          label: '$name (eliminata)',
          snapshotName: name,
        ),
      );
    }

    return options;
  }

  static Map<String, Medicine> _medicineById(Iterable<Therapy> therapies) {
    return {
      for (final therapy in therapies)
        for (final medicine in therapy.medicines) medicine.id: medicine,
    };
  }

  static bool _matchesStatus(IntakeRecord record, HistoryStatusFilter filter) {
    return switch (filter) {
      HistoryStatusFilter.all => true,
      HistoryStatusFilter.taken => record.status == IntakeStatus.taken,
      HistoryStatusFilter.skipped => record.status == IntakeStatus.skipped,
      HistoryStatusFilter.missed => record.status == IntakeStatus.missed,
    };
  }

  static bool _matchesPeriod(
    IntakeRecord record,
    HistoryPeriodFilter filter,
    DateTime referenceDate,
  ) {
    if (filter == HistoryPeriodFilter.all) return true;

    final today = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );
    final start = switch (filter) {
      HistoryPeriodFilter.today => today,
      HistoryPeriodFilter.last7Days => today.subtract(const Duration(days: 6)),
      HistoryPeriodFilter.last30Days => today.subtract(
        const Duration(days: 29),
      ),
      HistoryPeriodFilter.all => today,
    };
    final end = today.add(const Duration(days: 1));
    final recordDate = DateTime(
      record.scheduledDateTime.year,
      record.scheduledDateTime.month,
      record.scheduledDateTime.day,
    );

    return !recordDate.isBefore(start) && recordDate.isBefore(end);
  }

  static bool _matchesTherapy(
    IntakeRecord record,
    String? therapyId,
    Map<String, Medicine> medicineById,
  ) {
    if (therapyId == null) return true;
    final medicineId = record.medicineId;
    if (medicineId == null) return false;
    return medicineById[medicineId]?.therapyId == therapyId;
  }

  static bool _matchesMedicine(
    IntakeRecord record,
    String? medicineId,
    String? snapshotName,
    Map<String, Medicine> medicineById,
  ) {
    if (medicineId == null && snapshotName == null) return true;

    if (medicineId != null) {
      return record.medicineId == medicineId;
    }

    final currentMedicineId = record.medicineId;
    final hasCurrentMedicine =
        currentMedicineId != null &&
        medicineById.containsKey(currentMedicineId);
    if (hasCurrentMedicine) return false;

    return _normalize(record.medicineNameSnapshot) == _normalize(snapshotName!);
  }

  static String _normalize(String value) => value.trim().toLowerCase();
}
