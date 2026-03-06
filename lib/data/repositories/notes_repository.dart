import '../../models/note.dart';
import '../../models/app_settings.dart';
import '../../services/notes_service.dart';

/// Thin repository wrapper over NotesService.
/// Exists to keep the provider layer decoupled from raw service details
/// and to make future caching / pagination easy to add.
class NotesRepository {
  final NotesService _service;

  NotesRepository(this._service);

  List<Note> getAll({AppSortMode sortMode = AppSortMode.alphabetical}) =>
      _service.fetchAllNotes(sortMode: sortMode);

  Note? getById(int id) => _service.fetchNoteById(id);

  Note create({String title = 'Başlıksız Not', String content = ''}) =>
      _service.createNote(title: title, content: content);

  void update(int id, {String? title, String? content}) =>
      _service.updateNote(id, title: title, content: content);

  void softDelete(int id) => _service.softDeleteNote(id);

  Note duplicate(int sourceId) => _service.duplicateNote(sourceId);

  void reorder(List<int> orderedIds) => _service.reorder(orderedIds);
}
