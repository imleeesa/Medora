/// Stato dell'assunzione
enum IntakeStatus {
  taken, // Assunta
  missed, // Saltata
  skipped, // Dimenticata
}

/// Modello per il record di assunzione
class IntakeRecord {
  final String id;
  final String? medicineId;
  final String? profileId;
  final DateTime scheduledDateTime; // Orario previsto
  final DateTime? actualDateTime; // Orario reale
  final IntakeStatus status;
  final String? notes;
  final String medicineNameSnapshot;
  final String medicineDoseSnapshot;
  final DateTime createdAt;

  IntakeRecord({
    required this.id,
    required this.medicineId,
    this.profileId,
    required this.scheduledDateTime,
    this.actualDateTime,
    required this.status,
    this.notes,
    this.medicineNameSnapshot = '',
    this.medicineDoseSnapshot = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? scheduledDateTime;

  /// Converte in JSON per il database
  Map<String, dynamic> toJson() => {
    'id': id,
    'medicineId': medicineId,
    'profileId': profileId,
    'scheduledDateTime': scheduledDateTime.toIso8601String(),
    'actualDateTime': actualDateTime?.toIso8601String(),
    'status': status.toString().split('.').last,
    'notes': notes,
    'medicineNameSnapshot': medicineNameSnapshot,
    'medicineDoseSnapshot': medicineDoseSnapshot,
    'createdAt': createdAt.toIso8601String(),
  };

  /// Crea da JSON del database
  factory IntakeRecord.fromJson(Map<String, dynamic> json) => IntakeRecord(
    id: json['id'],
    medicineId: json['medicineId'],
    profileId: json['profileId'],
    scheduledDateTime: DateTime.parse(json['scheduledDateTime']),
    actualDateTime: json['actualDateTime'] != null
        ? DateTime.parse(json['actualDateTime'])
        : null,
    status: IntakeStatus.values.firstWhere(
      (s) => s.toString().split('.').last == json['status'],
    ),
    notes: json['notes'],
    medicineNameSnapshot: json['medicineNameSnapshot'] ?? '',
    medicineDoseSnapshot: json['medicineDoseSnapshot'] ?? '',
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : DateTime.parse(json['scheduledDateTime']),
  );

  /// Copia con modifiche
  IntakeRecord copyWith({
    String? id,
    String? medicineId,
    String? profileId,
    DateTime? scheduledDateTime,
    DateTime? actualDateTime,
    IntakeStatus? status,
    String? notes,
    String? medicineNameSnapshot,
    String? medicineDoseSnapshot,
    DateTime? createdAt,
  }) => IntakeRecord(
    id: id ?? this.id,
    medicineId: medicineId ?? this.medicineId,
    profileId: profileId ?? this.profileId,
    scheduledDateTime: scheduledDateTime ?? this.scheduledDateTime,
    actualDateTime: actualDateTime ?? this.actualDateTime,
    status: status ?? this.status,
    notes: notes ?? this.notes,
    medicineNameSnapshot: medicineNameSnapshot ?? this.medicineNameSnapshot,
    medicineDoseSnapshot: medicineDoseSnapshot ?? this.medicineDoseSnapshot,
    createdAt: createdAt ?? this.createdAt,
  );

  @override
  String toString() =>
      'IntakeRecord(id: $id, medicineId: $medicineId, status: $status)';
}
