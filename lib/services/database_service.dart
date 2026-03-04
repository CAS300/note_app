import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';
import '../core/constants.dart';

class DatabaseService {
  Database? _db;

  Database? get db => _db;

  void openDatabase(String workspacePath, String dbName) {
    closeDatabase();
    
    final dbPath = p.join(workspacePath, dbName);
    _db = sqlite3.open(dbPath);
    _initMetaTable(_db!);
  }

  void closeDatabase() {
    if (_db != null) {
      _db!.dispose();
      _db = null;
    }
  }

  void _initMetaTable(Database database) {
    database.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    _insertMetaIfMissing(database, 'app_id', AppConstants.appId);
    _insertMetaIfMissing(database, 'schema_version', '1');
    _insertMetaIfMissing(database, 'created_at', DateTime.now().millisecondsSinceEpoch.toString());
  }

  void _insertMetaIfMissing(Database database, String key, String value) {
    // Only execute if key doesnt exist
    final rs = database.select('SELECT key FROM meta WHERE key = ?', [key]);
    if (rs.isEmpty) {
        final stmt = database.prepare('INSERT INTO meta (key, value) VALUES (?, ?)');
        stmt.execute([key, value]);
        stmt.dispose();
    }
  }

  Future<bool> databaseExists(String workspacePath, String dbName) async {
    final file = File(p.join(workspacePath, dbName));
    return await file.exists();
  }
}
