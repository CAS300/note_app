import 'package:sqlite3/sqlite3.dart';
import '../models/note.dart';
import '../models/app_settings.dart';
import '../core/utils.dart';

/// Pure CRUD operations on the notes table.
/// Schema creation is handled by DatabaseService.
class NotesService {
  final Database _db;

  NotesService(this._db);

  /// Fetch notes using the specified sort mode.
  List<Note> fetchAllNotes({AppSortMode sortMode = AppSortMode.alphabetical}) {
    String orderClause;
    switch (sortMode) {
      case AppSortMode.alphabetical:
        orderClause = 'ORDER BY LOWER(title) ASC';
        break;
      case AppSortMode.updatedAt:
        orderClause = 'ORDER BY updated_at DESC';
        break;
      case AppSortMode.custom:
        orderClause = 'ORDER BY sort_order ASC, updated_at DESC';
        break;
    }

    final rs = _db.select(
      'SELECT * FROM notes WHERE is_deleted = 0 $orderClause',
    );
    return rs.map((row) => Note.fromMap(row)).toList();
  }

  Note? fetchNoteById(int id) {
    final rs = _db.select('SELECT * FROM notes WHERE id = ?', [id]);
    if (rs.isEmpty) return null;
    return Note.fromMap(rs.first);
  }

  /// Returns the next sort_order value (max + 1).
  int _nextSortOrder() {
    final rs = _db.select(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next_order FROM notes WHERE is_deleted = 0',
    );
    return rs.first['next_order'] as int;
  }

  Note createNote({String title = 'Başlıksız Not', String content = ''}) {
    final now = AppUtils.currentTimestamp();
    final order = _nextSortOrder();
    final stmt = _db.prepare('''
      INSERT INTO notes (title, content, group_id, created_at, updated_at, is_deleted, sort_order)
      VALUES (?, ?, NULL, ?, ?, 0, ?)
    ''');
    stmt.execute([title, content, now, now, order]);
    stmt.dispose();

    final id = _db.lastInsertRowId;
    return Note(
      id: id,
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
      sortOrder: order,
    );
  }

  void updateNote(int id, {String? title, String? content}) {
    final now = AppUtils.currentTimestamp();
    final parts = <String>[];
    final args = <Object?>[];

    if (title != null) {
      parts.add('title = ?');
      args.add(title);
    }
    if (content != null) {
      parts.add('content = ?');
      args.add(content);
    }
    if (parts.isEmpty) return;

    parts.add('updated_at = ?');
    args.add(now);
    args.add(id);

    final sql = 'UPDATE notes SET ${parts.join(', ')} WHERE id = ?';
    final stmt = _db.prepare(sql);
    stmt.execute(args);
    stmt.dispose();
  }

  void softDeleteNote(int id) {
    final now = AppUtils.currentTimestamp();
    final stmt = _db.prepare(
      'UPDATE notes SET is_deleted = 1, updated_at = ? WHERE id = ?',
    );
    stmt.execute([now, id]);
    stmt.dispose();
  }

  /// Duplicate a note (returns the new note).
  Note duplicateNote(int sourceId) {
    final source = fetchNoteById(sourceId);
    if (source == null) {
      return createNote();
    }
    return createNote(
      title: '${source.title} (kopya)',
      content: source.content,
    );
  }

  /// Bulk update sort_order for a list of note IDs in order.
  void reorder(List<int> orderedIds) {
    final stmt = _db.prepare('UPDATE notes SET sort_order = ? WHERE id = ?');
    for (int i = 0; i < orderedIds.length; i++) {
      stmt.execute([i, orderedIds[i]]);
    }
    stmt.dispose();
  }
}
