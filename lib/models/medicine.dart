import 'package:flutter/material.dart';

import 'medicine_schedule.dart';

/// Modello per una medicina
class Medicine {
  final String id;
  final String name;
  final String dose;
  final String? notes;
  final List<TimeOfDay> times; // Orari di assunzione
  final List<int> daysOfWeek; // 1=lunedì, 7=domenica
  final int stockQuantity; // Quantità attuale
  final int stockWarningThreshold; // Soglia minima
  final bool isActive;
  final String color; // Codice colore hex
  final String? icon; // Nome icona
  final int? iconCodePoint;
  final String? profileId;
  final String? therapyId;
  final List<MedicineSchedule> schedules;
  final DateTime createdAt;
  final DateTime updatedAt;

  Medicine({
    required this.id,
    required this.name,
    required this.dose,
    this.notes,
    required this.times,
    required this.daysOfWeek,
    required this.stockQuantity,
    required this.stockWarningThreshold,
    this.isActive = true,
    this.color = '#2E7D32',
    this.icon,
    this.iconCodePoint,
    this.profileId,
    this.therapyId,
    List<MedicineSchedule>? schedules,
    required this.createdAt,
    required this.updatedAt,
  }) : schedules =
           schedules ??
           times
               .map(
                 (time) => MedicineSchedule(
                   time: time,
                   daysOfWeek: List<int>.from(daysOfWeek),
                 ),
               )
               .toList(growable: false);

  /// Testo sicuro da usare nell'interfaccia quando il dosaggio non e definito.
  String get doseLabel =>
      dose.trim().isEmpty ? 'Dose non specificata' : dose.trim();

  /// Quantita' intera sicura da sottrarre alla scorta, se presente nella dose.
  int? get stockConsumptionAmount => stockConsumptionAmountFromDose(dose);

  static int? stockConsumptionAmountFromDose(String dose) {
    final match = RegExp(r'^(\d+)(?:\s|$)').firstMatch(dose.trim());
    if (match == null) return null;
    final amount = int.tryParse(match.group(1)!);
    return amount == null || amount <= 0 ? null : amount;
  }

  /// Verifica se la medicina deve essere assunta oggi
  bool shouldTakeToday() {
    final today = DateTime.now().weekday;
    return isActive && daysOfWeek.contains(today);
  }

  /// Restituisce la prossima assunzione
  TimeOfDay? getNextIntake() {
    if (!shouldTakeToday()) return null;
    final now = TimeOfDay.now();
    for (final time in times) {
      if (_compareTimeOfDay(time, now) > 0) {
        return time;
      }
    }
    return null;
  }

  /// Converte in JSON per il database
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'dose': dose,
    'notes': notes,
    'times': times.map((t) => '${t.hour}:${t.minute}').toList().join(','),
    'daysOfWeek': daysOfWeek.join(','),
    'stockQuantity': stockQuantity,
    'stockWarningThreshold': stockWarningThreshold,
    'isActive': isActive ? 1 : 0,
    'color': color,
    'icon': icon,
    'iconCodePoint': iconCodePoint,
    'profileId': profileId,
    'therapyId': therapyId,
    'schedules': schedules
        .map(
          (schedule) => {
            'hour': schedule.time.hour,
            'minute': schedule.time.minute,
            'daysOfWeek': schedule.daysOfWeek,
            'isActive': schedule.isActive,
            'createdAt': schedule.createdAt?.toIso8601String(),
            'updatedAt': schedule.updatedAt?.toIso8601String(),
          },
        )
        .toList(growable: false),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  /// Crea da JSON del database
  factory Medicine.fromJson(Map<String, dynamic> json) {
    final timesList = (json['times'] as String).split(',');
    final times = timesList.map((t) {
      final parts = t.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }).toList();

    final daysOfWeek = (json['daysOfWeek'] as String)
        .split(',')
        .map((d) => int.parse(d))
        .toList();

    final schedulesJson = json['schedules'] as List<dynamic>?;
    final schedules = schedulesJson
        ?.whereType<Map<String, dynamic>>()
        .map(
          (schedule) => MedicineSchedule(
            time: TimeOfDay(
              hour: schedule['hour'] as int,
              minute: schedule['minute'] as int,
            ),
            daysOfWeek: List<int>.from(schedule['daysOfWeek'] as List),
            isActive: schedule['isActive'] as bool? ?? true,
            createdAt: schedule['createdAt'] != null
                ? DateTime.parse(schedule['createdAt'] as String)
                : null,
            updatedAt: schedule['updatedAt'] != null
                ? DateTime.parse(schedule['updatedAt'] as String)
                : null,
          ),
        )
        .toList(growable: false);

    return Medicine(
      id: json['id'],
      name: json['name'],
      dose: json['dose'] as String? ?? '',
      notes: json['notes'],
      times: times,
      daysOfWeek: daysOfWeek,
      stockQuantity: json['stockQuantity'],
      stockWarningThreshold: json['stockWarningThreshold'],
      isActive: json['isActive'] == 1,
      color: json['color'] ?? '#2E7D32',
      icon: json['icon'],
      iconCodePoint: json['iconCodePoint'],
      profileId: json['profileId'],
      therapyId: json['therapyId'],
      schedules: schedules,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  /// Copia con modifiche
  Medicine copyWith({
    String? id,
    String? name,
    String? dose,
    String? notes,
    List<TimeOfDay>? times,
    List<int>? daysOfWeek,
    int? stockQuantity,
    int? stockWarningThreshold,
    bool? isActive,
    String? color,
    String? icon,
    int? iconCodePoint,
    String? profileId,
    String? therapyId,
    List<MedicineSchedule>? schedules,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    final resolvedTimes = times ?? this.times;
    final resolvedDaysOfWeek = daysOfWeek ?? this.daysOfWeek;
    final resolvedSchedules =
        schedules ??
        (times != null || daysOfWeek != null
            ? resolvedTimes
                  .map(
                    (time) => MedicineSchedule(
                      time: time,
                      daysOfWeek: List<int>.from(resolvedDaysOfWeek),
                    ),
                  )
                  .toList(growable: false)
            : this.schedules);

    return Medicine(
      id: id ?? this.id,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      notes: notes ?? this.notes,
      times: resolvedTimes,
      daysOfWeek: resolvedDaysOfWeek,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      stockWarningThreshold:
          stockWarningThreshold ?? this.stockWarningThreshold,
      isActive: isActive ?? this.isActive,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      profileId: profileId ?? this.profileId,
      therapyId: therapyId ?? this.therapyId,
      schedules: resolvedSchedules,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() => 'Medicine(id: $id, name: $name, dose: $dose)';
}

/// Helper per comparare TimeOfDay
int _compareTimeOfDay(TimeOfDay t1, TimeOfDay t2) {
  if (t1.hour != t2.hour) return t1.hour.compareTo(t2.hour);
  return t1.minute.compareTo(t2.minute);
}
