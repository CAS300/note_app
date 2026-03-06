import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/note.dart';
import '../models/app_settings.dart';
import '../data/repositories/notes_repository.dart';
import 'database_provider.dart';
import 'settings_provider.dart';

/// State holding the notes list and currently selected note.
class NotesState {
  final List<Note> notes;
  final int? selectedNoteId;

  NotesState({this.notes = const [], this.selectedNoteId});

  Note? get selectedNote {
    if (selectedNoteId == null) return null;
    try {
      return notes.firstWhere((n) => n.id == selectedNoteId);
    } catch (_) {
      return null;
    }
  }

  NotesState copyWith(
      {List<Note>? notes, int? selectedNoteId, bool clearSelection = false}) {
    return NotesState(
      notes: notes ?? this.notes,
      selectedNoteId:
          clearSelection ? null : (selectedNoteId ?? this.selectedNoteId),
    );
  }
}

class NotesNotifier extends StateNotifier<NotesState> {
  NotesRepository? _repo;
  AppSortMode _sortMode = AppSortMode.alphabetical;

  NotesNotifier() : super(NotesState());

  /// Called when the database connection changes.
  void attach(NotesRepository repo) {
    _repo = repo;
    reload();
  }

  void detach() {
    _repo = null;
    state = NotesState();
  }

  /// Update the sort mode and reload.
  void setSortMode(AppSortMode mode) {
    _sortMode = mode;
    reload();
  }

  void reload() {
    if (_repo == null) return;
    final all = _repo!.getAll(sortMode: _sortMode);
    final stillExists = state.selectedNoteId != null &&
        all.any((n) => n.id == state.selectedNoteId);
    state = NotesState(
      notes: all,
      selectedNoteId: stillExists ? state.selectedNoteId : null,
    );
  }

  void selectNote(int? id) {
    state = state.copyWith(selectedNoteId: id);
  }

  void createNote() {
    if (_repo == null) return;
    final note = _repo!.create();
    reload();
    state = state.copyWith(selectedNoteId: note.id);
  }

  void updateNote(int id, {String? title, String? content}) {
    if (_repo == null) return;
    _repo!.update(id, title: title, content: content);
    reload();
  }

  void deleteNote(int id) {
    if (_repo == null) return;
    _repo!.softDelete(id);
    final clearSel = state.selectedNoteId == id;
    reload();
    if (clearSel) {
      state = state.copyWith(clearSelection: true);
    }
  }

  void renameNote(int id, String newTitle) {
    if (_repo == null) return;
    _repo!.update(id, title: newTitle);
    reload();
  }

  void duplicateNote(int sourceId) {
    if (_repo == null) return;
    final dup = _repo!.duplicate(sourceId);
    reload();
    state = state.copyWith(selectedNoteId: dup.id);
  }

  /// Reorder notes by drag-and-drop. [orderedIds] is the new order of note ids.
  void reorder(List<int> orderedIds) {
    if (_repo == null) return;
    _repo!.reorder(orderedIds);
    reload();
  }
}

final notesProvider = StateNotifierProvider<NotesNotifier, NotesState>((ref) {
  final notifier = NotesNotifier();

  // Sync sort mode from settings.
  ref.listen<AppSettings>(settingsProvider, (prev, next) {
    notifier.setSortMode(next.sortMode);
  });

  // Listen to database connection changes and attach / detach automatically.
  ref.listen<DatabaseState>(databaseProvider, (prev, next) {
    if (next.isConnected && next.notesService != null) {
      notifier.attach(NotesRepository(next.notesService!));
      // Also apply current sort mode.
      final settings = ref.read(settingsProvider);
      notifier.setSortMode(settings.sortMode);
    } else {
      notifier.detach();
    }
  });

  // Handle the current state at creation time.
  final dbState = ref.read(databaseProvider);
  if (dbState.isConnected && dbState.notesService != null) {
    notifier.attach(NotesRepository(dbState.notesService!));
    final settings = ref.read(settingsProvider);
    notifier.setSortMode(settings.sortMode);
  }

  return notifier;
});
