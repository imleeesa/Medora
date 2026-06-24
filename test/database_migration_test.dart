import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meditrack/data/local_database.dart';

void main() {
  test('migrates medicine stock values from integer to real', () async {
    final executor = NativeDatabase.memory();
    await executor.ensureOpen(_MigrationSeedUser());
    await executor.runCustom('''
      CREATE TABLE medicines (
        id TEXT NOT NULL PRIMARY KEY,
        profile_id TEXT NOT NULL,
        therapy_id TEXT,
        name TEXT NOT NULL,
        dose TEXT NOT NULL,
        notes TEXT,
        color_value INTEGER NOT NULL,
        icon_code_point INTEGER NOT NULL,
        stock_quantity INTEGER NOT NULL,
        stock_warning_threshold INTEGER NOT NULL,
        is_active INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    await executor.runCustom('''
      INSERT INTO medicines VALUES (
        'medicine-1', 'profile-1', 'therapy-1', 'Medicina', '1 compressa',
        NULL, 4281234567, 0, 10, 2, 1, 0, 0
      )
    ''');
    await executor.runCustom('PRAGMA user_version = 1');

    final database = LocalDatabase.forTesting(executor);
    addTearDown(database.close);

    final row = await database
        .customSelect(
          'SELECT stock_quantity, stock_warning_threshold FROM medicines',
        )
        .getSingle();

    expect(row.read<double>('stock_quantity'), 10.0);
    expect(row.read<double>('stock_warning_threshold'), 2.0);
  });
}

class _MigrationSeedUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 1;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
