import 'package:drift/drift.dart';

import 'user_profiles_table.dart';

class Therapies extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(UserProfiles, #id)();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  IntColumn get colorValue => integer()();
  IntColumn get iconCodePoint => integer()();
  TextColumn get status => text()();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
