import '../../models/note.dart';
import '../../models/app_settings.dart';
import '../../services/notes_service.dart';

/// Thin repository wrapper over NotesService.
class NotesRepository {
  final NotesService _service;

  NotesRepository(this._service);

  List<Note> getAll({
    AppSortMode sortMode = AppSortMode.alphabetical,
    int? groupId,
    bool filterByGroup = false,
  }) =>
      _service.fetchAllNotes(
        sortMode: sortMode,
        groupId: groupId,
        filterByGroup: filterByGroup,
      );

  Note? getById(int id) => _service.fetchNoteById(id);

  Note create(
          {String title = 'Başlıksız Not',
          String content = '',
          List<int> groupIds = const []}) =>
      _service.createNote(title: title, content: content, groupIds: groupIds);

  void update(int id, {String? title, String? content, List<int>? groupIds}) =>
      _service.updateNote(id, title: title, content: content, groupIds: groupIds);

  void softDelete(int id) => _service.softDeleteNote(id);

  Note duplicate(int sourceId) => _service.duplicateNote(sourceId);

  void reorder(List<int> orderedIds) => _service.reorder(orderedIds);

  void toggleShortcut(int id) => _service.toggleShortcut(id);
}
