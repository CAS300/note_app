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
    _ensureSchema(_db!);
  }

  void closeDatabase() {
    if (_db != null) {
      _db!.dispose();
      _db = null;
    }
  }

  void _ensureSchema(Database database) {
    // Meta table
    database.execute('''
      CREATE TABLE IF NOT EXISTS meta (
        key TEXT PRIMARY KEY,
        value TEXT
      )
    ''');

    _insertMetaIfMissing(database, 'app_id', AppConstants.appId);
    _insertMetaIfMissing(database, 'schema_version', '1');
    _insertMetaIfMissing(
      database,
      'created_at',
      DateTime.now().millisecondsSinceEpoch.toString(),
    );

    // Notes table (v1)
    database.execute('''
      CREATE TABLE IF NOT EXISTS notes (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        group_id INTEGER NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        is_deleted INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Groups table
    database.execute('''
      CREATE TABLE IF NOT EXISTS groups (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Migrations
    _migrateAddSortOrder(database);
    _migrateAddIsShortcut(database);
  }

  /// Safely adds the sort_order column to existing databases.
  void _migrateAddSortOrder(Database database) {
    final cols = database.select("PRAGMA table_info('notes')");
    final hasSortOrder = cols.any((row) => row['name'] == 'sort_order');
    if (!hasSortOrder) {
      database.execute(
        'ALTER TABLE notes ADD COLUMN sort_order INTEGER NOT NULL DEFAULT 0',
      );
      database.execute('''
        UPDATE notes SET sort_order = (
          SELECT COUNT(*) FROM notes AS n2
          WHERE n2.created_at < notes.created_at
        )
      ''');
    }
  }

  /// Safely adds the is_shortcut column to existing databases.
  void _migrateAddIsShortcut(Database database) {
    final cols = database.select("PRAGMA table_info('notes')");
    final hasIsShortcut = cols.any((row) => row['name'] == 'is_shortcut');
    if (!hasIsShortcut) {
      database.execute(
        'ALTER TABLE notes ADD COLUMN is_shortcut INTEGER NOT NULL DEFAULT 0',
      );
    }
  }

  void _insertMetaIfMissing(Database database, String key, String value) {
    final rs = database.select('SELECT key FROM meta WHERE key = ?', [key]);
    if (rs.isEmpty) {
      final stmt = database.prepare(
        'INSERT INTO meta (key, value) VALUES (?, ?)',
      );
      stmt.execute([key, value]);
      stmt.dispose();
    }
  }

  Future<bool> databaseExists(String workspacePath, String dbName) async {
    final file = File(p.join(workspacePath, dbName));
    return await file.exists();
  }
}
