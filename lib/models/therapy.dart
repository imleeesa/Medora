import 'medicine.dart';

class Therapy {
  final String id;
  final String name;
  final String color;
  final List<Medicine> medicines;
  final bool isActive;

  const Therapy({
    required this.id,
    required this.name,
    required this.color,
    required this.medicines,
    this.isActive = true,
  });

  Therapy copyWith({
    String? id,
    String? name,
    String? color,
    List<Medicine>? medicines,
    bool? isActive,
  }) {
    return Therapy(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      medicines: medicines ?? this.medicines,
      isActive: isActive ?? this.isActive,
    );
  }
}
