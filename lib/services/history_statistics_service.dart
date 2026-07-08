import '../models/intake_record.dart';
import '../models/medicine.dart';
import '../models/therapy.dart';

enum StatisticsPeriod { today, last7Days, last30Days, all }

enum AdherenceTrendPeriod { last7Days, last30Days, all }

class IntakeStatistics {
  final int totalRecords;
  final int taken;
  final int skipped;
  final int missed;

  const IntakeStatistics({
    required this.totalRecords,
    required this.taken,
    required this.skipped,
    required this.missed,
  });

  int get adherenceDenominator => taken + skipped + missed;

  int get evaluatedRecords => adherenceDenominator;

  double get adherenceRatio =>
      adherenceDenominator == 0 ? 0 : taken / adherenceDenominator;

  int get adherencePercent => (adherenceRatio * 100).round();
}

class DailyAdherencePoint {
  final DateTime date;
  final int taken;
  final int skipped;
  final int missed;

  const DailyAdherencePoint({
    required this.date,
    required this.taken,
    required this.skipped,
    required this.missed,
  });

  int get evaluatedRecords => taken + skipped + missed;

  double? get adherenceRatio =>
      evaluatedRecords == 0 ? null : taken / evaluatedRecords;

  int? get adherencePercent {
    final ratio = adherenceRatio;
    return ratio == null ? null : (ratio * 100).round();
  }
}

class NamedIntakeStatistics {
  final String id;
  final String name;
  final IntakeStatistics statistics;
  final bool isDeleted;

  const NamedIntakeStatistics({
    required this.id,
    required this.name,
    required this.statistics,
    this.isDeleted = false,
  });
}

class HistoryStatisticsSummary {
  final IntakeStatistics all;
  final IntakeStatistics today;
  final IntakeStatistics last7Days;
  final IntakeStatistics last30Days;
  final List<NamedIntakeStatistics> byMedicine;
  final List<NamedIntakeStatistics> byTherapy;
  final int unattributedTherapyRecords;

  const HistoryStatisticsSummary({
    required this.all,
    required this.today,
    required this.last7Days,
    required this.last30Days,
    required this.byMedicine,
    required this.byTherapy,
    required this.unattributedTherapyRecords,
  });
}

class HistoryStatisticsService {
  const HistoryStatisticsService._();

  static HistoryStatisticsSummary calculate({
    required Iterable<IntakeRecord> records,
    required Iterable<Therapy> therapies,
    required DateTime referenceDate,
  }) {
    final recordList = records.toList(growable: false);
    final medicineById = _medicineById(therapies);
    final therapyById = {for (final therapy in therapies) therapy.id: therapy};

    return HistoryStatisticsSummary(
      all: _calculate(recordList),
      today: _calculate(
        _recordsForPeriod(recordList, StatisticsPeriod.today, referenceDate),
      ),
      last7Days: _calculate(
        _recordsForPeriod(
          recordList,
          StatisticsPeriod.last7Days,
          referenceDate,
        ),
      ),
      last30Days: _calculate(
        _recordsForPeriod(
          recordList,
          StatisticsPeriod.last30Days,
          referenceDate,
        ),
      ),
      byMedicine: _byMedicine(recordList, medicineById),
      byTherapy: _byTherapy(recordList, medicineById, therapyById),
      unattributedTherapyRecords: _unattributedTherapyRecordCount(
        recordList,
        medicineById,
        therapyById,
      ),
    );
  }

  static List<DailyAdherencePoint> adherenceTrend({
    required Iterable<IntakeRecord> records,
    required Iterable<Therapy> therapies,
    required DateTime referenceDate,
    required AdherenceTrendPeriod period,
    String? therapyId,
    String? medicineId,
    String? medicineSnapshotName,
  }) {
    final today = _dateOnly(referenceDate);
    final recordList = records.toList(growable: false);
    final firstRecordDate = recordList.isEmpty
        ? today
        : recordList
              .map((record) => _dateOnly(record.scheduledDateTime))
              .reduce(
                (first, second) => first.isBefore(second) ? first : second,
              );
    final start = switch (period) {
      AdherenceTrendPeriod.last7Days => today.subtract(const Duration(days: 6)),
      AdherenceTrendPeriod.last30Days => today.subtract(
        const Duration(days: 29),
      ),
      AdherenceTrendPeriod.all =>
        firstRecordDate.isAfter(today) ? today : firstRecordDate,
    };
    final medicineById = _medicineById(therapies);
    final normalizedSnapshot = medicineSnapshotName == null
        ? null
        : _normalize(medicineSnapshotName);
    final grouped = <DateTime, List<IntakeRecord>>{};

    for (final record in recordList) {
      final date = _dateOnly(record.scheduledDateTime);
      if (date.isBefore(start) || date.isAfter(today)) continue;
      if (!_matchesTrendFilters(
        record: record,
        medicineById: medicineById,
        therapyId: therapyId,
        medicineId: medicineId,
        normalizedSnapshotName: normalizedSnapshot,
      )) {
        continue;
      }
      grouped.putIfAbsent(date, () => []).add(record);
    }

    final points = <DailyAdherencePoint>[];
    for (
      var date = start;
      !date.isAfter(today);
      date = date.add(const Duration(days: 1))
    ) {
      final statistics = _calculate(grouped[date] ?? const []);
      points.add(
        DailyAdherencePoint(
          date: date,
          taken: statistics.taken,
          skipped: statistics.skipped,
          missed: statistics.missed,
        ),
      );
    }
    return points;
  }

  static IntakeStatistics _calculate(Iterable<IntakeRecord> records) {
    var totalRecords = 0;
    var taken = 0;
    var skipped = 0;
    var missed = 0;

    for (final record in records) {
      totalRecords++;
      switch (record.status) {
        case IntakeStatus.taken:
          taken++;
        case IntakeStatus.skipped:
          skipped++;
        case IntakeStatus.missed:
          missed++;
        case IntakeStatus.scheduled:
          break;
      }
    }

    return IntakeStatistics(
      totalRecords: totalRecords,
      taken: taken,
      skipped: skipped,
      missed: missed,
    );
  }

  static Iterable<IntakeRecord> _recordsForPeriod(
    Iterable<IntakeRecord> records,
    StatisticsPeriod period,
    DateTime referenceDate,
  ) {
    if (period == StatisticsPeriod.all) return records;

    final today = _dateOnly(referenceDate);
    final start = switch (period) {
      StatisticsPeriod.today => today,
      StatisticsPeriod.last7Days => today.subtract(const Duration(days: 6)),
      StatisticsPeriod.last30Days => today.subtract(const Duration(days: 29)),
      StatisticsPeriod.all => today,
    };
    final end = today.add(const Duration(days: 1));

    return records.where((record) {
      final recordDate = _dateOnly(record.scheduledDateTime);
      return !recordDate.isBefore(start) && recordDate.isBefore(end);
    });
  }

  static List<NamedIntakeStatistics> _byMedicine(
    Iterable<IntakeRecord> records,
    Map<String, Medicine> medicineById,
  ) {
    final grouped = <String, List<IntakeRecord>>{};
    final names = <String, String>{};
    final deleted = <String, bool>{};

    for (final record in records) {
      final medicineId = record.medicineId;
      final currentMedicine = medicineId == null
          ? null
          : medicineById[medicineId];
      final key = currentMedicine == null
          ? 'snapshot:${_normalize(_medicineSnapshotName(record))}'
          : 'medicine:${currentMedicine.id}';
      grouped.putIfAbsent(key, () => []).add(record);
      names[key] = currentMedicine?.name ?? _medicineSnapshotName(record);
      deleted[key] = currentMedicine == null;
    }

    return _namedStatistics(grouped, names, deleted);
  }

  static List<NamedIntakeStatistics> _byTherapy(
    Iterable<IntakeRecord> records,
    Map<String, Medicine> medicineById,
    Map<String, Therapy> therapyById,
  ) {
    final grouped = <String, List<IntakeRecord>>{};
    final names = <String, String>{};

    for (final record in records) {
      final medicineId = record.medicineId;
      if (medicineId == null) continue;
      final medicine = medicineById[medicineId];
      final therapyId = medicine?.therapyId;
      if (therapyId == null) continue;
      final therapy = therapyById[therapyId];
      if (therapy == null) continue;
      final key = 'therapy:${therapy.id}';
      grouped.putIfAbsent(key, () => []).add(record);
      names[key] = therapy.name;
    }

    return _namedStatistics(grouped, names, const {});
  }

  static int _unattributedTherapyRecordCount(
    Iterable<IntakeRecord> records,
    Map<String, Medicine> medicineById,
    Map<String, Therapy> therapyById,
  ) {
    var count = 0;
    for (final record in records) {
      final medicineId = record.medicineId;
      if (medicineId == null) {
        count++;
        continue;
      }
      final therapyId = medicineById[medicineId]?.therapyId;
      if (therapyId == null || !therapyById.containsKey(therapyId)) {
        count++;
      }
    }
    return count;
  }

  static List<NamedIntakeStatistics> _namedStatistics(
    Map<String, List<IntakeRecord>> grouped,
    Map<String, String> names,
    Map<String, bool> deleted,
  ) {
    final result = grouped.entries
        .map(
          (entry) => NamedIntakeStatistics(
            id: entry.key,
            name: names[entry.key] ?? 'Non disponibile',
            statistics: _calculate(entry.value),
            isDeleted: deleted[entry.key] ?? false,
          ),
        )
        .toList();

    result.sort((first, second) {
      final adherenceCompare = second.statistics.adherencePercent.compareTo(
        first.statistics.adherencePercent,
      );
      if (adherenceCompare != 0) return adherenceCompare;
      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });
    return result;
  }

  static Map<String, Medicine> _medicineById(Iterable<Therapy> therapies) {
    return {
      for (final therapy in therapies)
        for (final medicine in therapy.medicines) medicine.id: medicine,
    };
  }

  static String _medicineSnapshotName(IntakeRecord record) {
    final snapshot = record.medicineNameSnapshot.trim();
    return snapshot.isEmpty ? 'Medicina non disponibile' : snapshot;
  }

  static String _normalize(String value) => value.trim().toLowerCase();

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static bool _matchesTrendFilters({
    required IntakeRecord record,
    required Map<String, Medicine> medicineById,
    required String? therapyId,
    required String? medicineId,
    required String? normalizedSnapshotName,
  }) {
    final recordMedicineId = record.medicineId;

    if (therapyId != null) {
      if (recordMedicineId == null) return false;
      if (medicineById[recordMedicineId]?.therapyId != therapyId) {
        return false;
      }
    }

    if (medicineId != null) {
      return recordMedicineId == medicineId;
    }

    if (normalizedSnapshotName != null) {
      final hasCurrentMedicine =
          recordMedicineId != null &&
          medicineById.containsKey(recordMedicineId);
      if (hasCurrentMedicine) return false;
      return _normalize(record.medicineNameSnapshot) == normalizedSnapshotName;
    }

    return true;
  }
}
