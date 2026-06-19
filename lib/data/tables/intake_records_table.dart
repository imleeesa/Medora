import 'package:drift/drift.dart';

import 'medicines_table.dart';
import 'user_profiles_table.dart';

class IntakeRecords extends Table {
  TextColumn get id => text()();
  TextColumn get medicineId => text().nullable().references(Medicines, #id)();
  TextColumn get profileId => text().references(UserProfiles, #id)();
  DateTimeColumn get scheduledDateTime => dateTime()();
  DateTimeColumn get actualDateTime => dateTime().nullable()();
  TextColumn get status => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get medicineNameSnapshot => text()();
  TextColumn get medicineDoseSnapshot => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
