import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/app_settings_table.dart';
import 'tables/intake_records_table.dart';
import 'tables/medicine_schedules_table.dart';
import 'tables/medicines_table.dart';
import 'tables/therapies_table.dart';
import 'tables/user_profiles_table.dart';

part 'local_database.g.dart';

@DriftDatabase(
  tables: [
    UserProfiles,
    AppSettings,
    Therapies,
    Medicines,
    MedicineSchedules,
    IntakeRecords,
  ],
)
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase() : super(_openConnection());

  LocalDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.alterTable(
          TableMigration(
            medicines,
            columnTransformer: {
              medicines.stockQuantity: const CustomExpression<double>(
                'CAST(stock_quantity AS REAL)',
              ),
              medicines.stockWarningThreshold: const CustomExpression<double>(
                'CAST(stock_warning_threshold AS REAL)',
              ),
            },
          ),
        );
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(p.join(directory.path, 'meditrack.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
