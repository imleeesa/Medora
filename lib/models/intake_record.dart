/// Stato dell'assunzione
enum IntakeStatus {
  taken, // Assunta
  missed, // Saltata
  skipped, // Dimenticata
}

/// Modello per il record di assunzione
class IntakeRecord {
  final String id;
  final String medicineId;
  final DateTime scheduledDateTime; // Orario previsto
  final DateTime? actualDateTime; // Orario reale
  final IntakeStatus status;
  final String? notes;

  IntakeRecord({
    required this.id,
    required this.medicineId,
    required this.scheduledDateTime,
    this.actualDateTime,
    required this.status,
    this.notes,
  });

  /// Converte in JSON per il database
  Map<String, dynamic> toJson() => {
    'id': id,
    'medicineId': medicineId,
    'scheduledDateTime': scheduledDateTime.toIso8601String(),
    'actualDateTime': actualDateTime?.toIso8601String(),
    'status': status.toString().split('.').last,
    'notes': notes,
  };

  /// Crea da JSON del database
  factory IntakeRecord.fromJson(Map<String, dynamic> json) => IntakeRecord(
    id: json['id'],
    medicineId: json['medicineId'],
    scheduledDateTime: DateTime.parse(json['scheduledDateTime']),
    actualDateTime: json['actualDateTime'] != null
        ? DateTime.parse(json['actualDateTime'])
        : null,
    status: IntakeStatus.values.firstWhere(
      (s) => s.toString().split('.').last == json['status'],
    ),
    notes: json['notes'],
  );

  /// Copia con modifiche
  IntakeRecord copyWith({
    String? id,
    String? medicineId,
    DateTime? scheduledDateTime,
    DateTime? actualDateTime,
    IntakeStatus? status,
    String? notes,
  }) => IntakeRecord(
    id: id ?? this.id,
    medicineId: medicineId ?? this.medicineId,
    scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
    actualDateTime: actualDateTime ?? this.actualDateTime,
    status: status ?? this.status,
    notes: notes ?? this.notes,
  );

  @override
  String toString() =>
      'IntakeRecord(id: $id, medicineId: $medicineId, status: $status)';
}
