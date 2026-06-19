import 'package:drift/drift.dart';

import 'medicines_table.dart';

class MedicineSchedules extends Table {
  TextColumn get id => text()();
  TextColumn get medicineId => text().references(Medicines, #id)();
  IntColumn get hour => integer()();
  IntColumn get minute => integer()();
  IntColumn get dayOfWeek => integer()();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
