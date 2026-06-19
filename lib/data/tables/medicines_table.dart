import 'package:drift/drift.dart';

import 'therapies_table.dart';
import 'user_profiles_table.dart';

class Medicines extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(UserProfiles, #id)();
  TextColumn get therapyId => text().nullable().references(Therapies, #id)();
  TextColumn get name => text()();
  TextColumn get dose => text()();
  TextColumn get notes => text().nullable()();
  IntColumn get colorValue => integer()();
  IntColumn get iconCodePoint => integer()();
  IntColumn get stockQuantity => integer()();
  IntColumn get stockWarningThreshold => integer()();
  BoolColumn get isActive => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
