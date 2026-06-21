import 'package:flutter/material.dart';

class MedicineSchedule {
  final TimeOfDay time;
  final List<int> daysOfWeek;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MedicineSchedule({
    required this.time,
    required this.daysOfWeek,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  MedicineSchedule copyWith({
    TimeOfDay? time,
    List<int>? daysOfWeek,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MedicineSchedule(
      time: time ?? this.time,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
