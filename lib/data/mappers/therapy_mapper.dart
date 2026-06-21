import 'package:drift/drift.dart';

import '../../models/medicine.dart' as app_medicine;
import '../../models/therapy.dart' as app;
import '../local_database.dart' as db;
import 'color_value_mapper.dart';

class TherapyMapper {
  const TherapyMapper._();

  static app.Therapy fromDatabase(
    db.Therapy therapy, {
    List<app_medicine.Medicine> medicines = const [],
  }) {
    return app.Therapy(
      id: therapy.id,
      profileId: therapy.profileId,
      name: therapy.name,
      description: therapy.description,
      color: ColorValueMapper.fromColorValue(therapy.colorValue),
      iconCodePoint: therapy.iconCodePoint,
      isActive: therapy.status == 'active',
      startDate: therapy.startDate,
      endDate: therapy.endDate,
      createdAt: therapy.createdAt,
      updatedAt: therapy.updatedAt,
      medicines: medicines,
    );
  }

  static db.TherapiesCompanion toCompanion(app.Therapy therapy) {
    final profileId = therapy.profileId;
    if (profileId == null) {
      throw StateError('A therapy must have a profileId before persistence.');
    }

    final now = DateTime.now();
    return db.TherapiesCompanion.insert(
      id: therapy.id,
      profileId: profileId,
      name: therapy.name,
      description: Value(therapy.description),
      colorValue: ColorValueMapper.toColorValue(therapy.color),
      iconCodePoint: therapy.iconCodePoint ?? 0,
      status: therapy.isActive ? 'active' : 'inactive',
      startDate: Value(therapy.startDate),
      endDate: Value(therapy.endDate),
      createdAt: therapy.createdAt ?? now,
      updatedAt: therapy.updatedAt ?? now,
    );
  }
}
