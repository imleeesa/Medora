import 'medicine.dart';

class Therapy {
  final String id;
  final String name;
  final String color;
  final List<Medicine> medicines;
  final bool isActive;
  final String? profileId;
  final String? description;
  final int? iconCodePoint;
  final DateTime? startDate;
  final DateTime? endDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Therapy({
    required this.id,
    required this.name,
    required this.color,
    required this.medicines,
    this.isActive = true,
    this.profileId,
    this.description,
    this.iconCodePoint,
    this.startDate,
    this.endDate,
    this.createdAt,
    this.updatedAt,
  });

  Therapy copyWith({
    String? id,
    String? name,
    String? color,
    List<Medicine>? medicines,
    bool? isActive,
    String? profileId,
    String? description,
    int? iconCodePoint,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Therapy(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      medicines: medicines ?? this.medicines,
      isActive: isActive ?? this.isActive,
      profileId: profileId ?? this.profileId,
      description: description ?? this.description,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
