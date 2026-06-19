import 'local_database.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  LocalDatabase? _database;

  LocalDatabase get database {
    return _database ??= LocalDatabase();
  }

  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
