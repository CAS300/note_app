import 'package:sqlite3/sqlite3.dart';
import '../models/note.dart';
import '../models/app_settings.dart';
import '../core/utils.dart';

/// Pure CRUD operations on the notes table.
/// Schema creation is handled by DatabaseService.
class NotesService {
  final Database _db;

  NotesService(this._db);

  /// Fetch notes with sort mode and optional group filter.
  List<Note> fetchAllNotes({
    AppSortMode sortMode = AppSortMode.alphabetical,
    int? groupId,
    bool filterByGroup = false,
  }) {
    String orderClause;
    switch (sortMode) {
      case AppSortMode.alphabetical:
        orderClause = 'ORDER BY LOWER(n.title) ASC';
        break;
      case AppSortMode.updatedAt:
        orderClause = 'ORDER BY n.updated_at DESC';
        break;
      case AppSortMode.custom:
        orderClause = 'ORDER BY n.sort_order ASC, n.updated_at DESC';
        break;
    }

    String whereClause = 'WHERE n.is_deleted = 0';
    final args = <Object?>[];

    if (filterByGroup && groupId != null) {
      whereClause += ' AND n.id IN (SELECT note_id FROM note_groups WHERE group_id = ?)';
      args.add(groupId);
    }

    final rs = _db.select('''
      SELECT n.*, GROUP_CONCAT(ng.group_id) as groups_concat
      FROM notes n
      LEFT JOIN note_groups ng ON n.id = ng.note_id
      $whereClause
      GROUP BY n.id
      $orderClause
    ''', args);
    return rs.map((row) => Note.fromMap(row)).toList();
  }

  Note? fetchNoteById(int id) {
    final rs = _db.select('''
      SELECT n.*, GROUP_CONCAT(ng.group_id) as groups_concat
      FROM notes n
      LEFT JOIN note_groups ng ON n.id = ng.note_id
      WHERE n.id = ?
      GROUP BY n.id
    ''', [id]);
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

  Note createNote({
    String title = 'Başlıksız Not', 
    String content = '', 
    List<int> groupIds = const [],
  }) {
    final now = AppUtils.currentTimestamp();
    final order = _nextSortOrder();
    final stmt = _db.prepare('''
      INSERT INTO notes (title, content, created_at, updated_at, is_deleted, sort_order, is_shortcut)
      VALUES (?, ?, ?, ?, 0, ?, 0)
    ''');
    stmt.execute([title, content, now, now, order]);
    stmt.dispose();

    final id = _db.lastInsertRowId;
    
    if (groupIds.isNotEmpty) {
      final grpStmt = _db.prepare('INSERT INTO note_groups (note_id, group_id) VALUES (?, ?)');
      for (final gid in groupIds) {
        grpStmt.execute([id, gid]);
      }
      grpStmt.dispose();
    }

    return Note(
      id: id,
      title: title,
      content: content,
      groupIds: groupIds,
      createdAt: now,
      updatedAt: now,
      sortOrder: order,
    );
  }

  void updateNote(int id, {String? title, String? content, List<int>? groupIds}) {
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
    
    if (parts.isNotEmpty) {
      parts.add('updated_at = ?');
      args.add(now);
      args.add(id);

      final sql = 'UPDATE notes SET ${parts.join(', ')} WHERE id = ?';
      final stmt = _db.prepare(sql);
      stmt.execute(args);
      stmt.dispose();
    }

    if (groupIds != null) {
      _db.execute('DELETE FROM note_groups WHERE note_id = ?', [id]);
      if (groupIds.isNotEmpty) {
        final grpStmt = _db.prepare('INSERT INTO note_groups (note_id, group_id) VALUES (?, ?)');
        for (final gid in groupIds) {
          grpStmt.execute([id, gid]);
        }
        grpStmt.dispose();
      }
      _db.execute('UPDATE notes SET updated_at = ? WHERE id = ?', [now, id]);
    }
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
      groupIds: source.groupIds,
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

  /// Toggle shortcut mode for a note.
  void toggleShortcut(int id) {
    final stmt = _db.prepare(
      'UPDATE notes SET is_shortcut = CASE WHEN is_shortcut = 0 THEN 1 ELSE 0 END WHERE id = ?',
    );
    stmt.execute([id]);
    stmt.dispose();
  }
}
