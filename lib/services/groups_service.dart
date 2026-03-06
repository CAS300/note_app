import 'package:sqlite3/sqlite3.dart';
import '../models/group.dart';
import '../core/utils.dart';

/// CRUD operations on the groups table.
/// Schema creation is handled by DatabaseService.
class GroupsService {
  final Database _db;

  GroupsService(this._db);

  List<Group> fetchAll() {
    final rs = _db.select('SELECT * FROM groups ORDER BY name ASC');
    return rs.map((row) => Group.fromMap(row)).toList();
  }

  Group? fetchById(int id) {
    final rs = _db.select('SELECT * FROM groups WHERE id = ?', [id]);
    if (rs.isEmpty) return null;
    return Group.fromMap(rs.first);
  }

  Group create({required String name, required String color}) {
    final now = AppUtils.currentTimestamp();
    final stmt = _db.prepare(
      'INSERT INTO groups (name, color, created_at) VALUES (?, ?, ?)',
    );
    stmt.execute([name, color, now]);
    stmt.dispose();
    return Group(
        id: _db.lastInsertRowId, name: name, color: color, createdAt: now);
  }

  void rename(int id, String newName) {
    final stmt = _db.prepare('UPDATE groups SET name = ? WHERE id = ?');
    stmt.execute([newName, id]);
    stmt.dispose();
  }

  void updateColor(int id, String newColor) {
    final stmt = _db.prepare('UPDATE groups SET color = ? WHERE id = ?');
    stmt.execute([newColor, id]);
    stmt.dispose();
  }

  /// Deletes group and sets all notes in it to group_id = NULL.
  void delete(int id) {
    final stmt1 =
        _db.prepare('UPDATE notes SET group_id = NULL WHERE group_id = ?');
    stmt1.execute([id]);
    stmt1.dispose();

    final stmt2 = _db.prepare('DELETE FROM groups WHERE id = ?');
    stmt2.execute([id]);
    stmt2.dispose();
  }

  /// Assign a note to a group.
  void assignNote(int noteId, int groupId) {
    final stmt = _db.prepare('UPDATE notes SET group_id = ? WHERE id = ?');
    stmt.execute([groupId, noteId]);
    stmt.dispose();
  }

  /// Remove a note from its group.
  void removeNoteFromGroup(int noteId) {
    final stmt = _db.prepare('UPDATE notes SET group_id = NULL WHERE id = ?');
    stmt.execute([noteId]);
    stmt.dispose();
  }
}
