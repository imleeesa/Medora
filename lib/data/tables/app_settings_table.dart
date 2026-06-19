import 'package:drift/drift.dart';

import 'user_profiles_table.dart';

class AppSettings extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text().references(UserProfiles, #id)();
  TextColumn get themeMode => text()();
  BoolColumn get notificationsEnabled => boolean()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
