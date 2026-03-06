import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notes_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../models/note.dart';
import '../../core/theme_definitions.dart';

class MainEditorPanel extends ConsumerStatefulWidget {
  const MainEditorPanel({super.key});

  @override
  ConsumerState<MainEditorPanel> createState() => _MainEditorPanelState();
}

class _MainEditorPanelState extends ConsumerState<MainEditorPanel> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  Timer? _saveTimer;
  int? _loadedNoteId;

  @override
  void dispose() {
    _flushSave();
    _titleController.dispose();
    _contentController.dispose();
    _saveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NoteAppColors>()!;
    final notesState = ref.watch(notesProvider);
    final dbState = ref.watch(databaseProvider);
    final workspaceState = ref.watch(workspaceProvider);
    final manifest = workspaceState.manifest;
    final note = notesState.selectedNote;

    // Sync controllers when a different note is selected
    if (note != null && note.id != _loadedNoteId) {
      _flushSave();
      _loadedNoteId = note.id;
      _titleController.text = note.title;
      _contentController.text = note.content;
    } else if (note == null && _loadedNoteId != null) {
      _flushSave();
      _loadedNoteId = null;
      _titleController.clear();
      _contentController.clear();
    }

    return Column(
      children: [
        // ── Top Bar ──
        _buildTopBar(theme, colors, manifest, dbState),
        Container(height: 1, color: colors.border),

        // ── Editor ──
        Expanded(
          child: note != null
              ? _buildEditor(theme, colors, note)
              : _buildEmptyState(theme, colors),
        ),
      ],
    );
  }

  Widget _buildTopBar(ThemeData theme, NoteAppColors colors, dynamic manifest,
      DatabaseState dbState) {
    final databases = manifest?.databases ?? [];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      color: theme.scaffoldBackgroundColor,
      child: Row(
        children: [
          if (databases.isNotEmpty)
            PopupMenuButton<String>(
              tooltip: 'Veritabanı Değiştir',
              offset: const Offset(0, 40),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.storage_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    _activeLabel(manifest, dbState),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 16, color: colors.textMuted),
                ],
              ),
              itemBuilder: (_) => databases.map<PopupMenuEntry<String>>((db) {
                final isActive = db.name == dbState.activeDbName;
                return PopupMenuItem<String>(
                  value: db.name,
                  child: Row(
                    children: [
                      Icon(
                        isActive
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        size: 16,
                        color: isActive ? colors.primary : colors.textMuted,
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(db.label,
                              style: theme.textTheme.titleMedium
                                  ?.copyWith(fontSize: 14)),
                          Text(db.name,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
              onSelected: (dbName) {
                _flushSave();
                ref.read(databaseProvider.notifier).switchDatabase(dbName);
              },
            ),
          const Spacer(),
        ],
      ),
    );
  }

  String _activeLabel(dynamic manifest, DatabaseState dbState) {
    if (manifest == null || dbState.activeDbName == null) return 'Seçili değil';
    for (final db in manifest.databases) {
      if (db.name == dbState.activeDbName) return db.label;
    }
    return dbState.activeDbName!;
  }

  Widget _buildEditor(ThemeData theme, NoteAppColors colors, Note note) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title Field ──
          TextField(
            controller: _titleController,
            onChanged: (_) => _scheduleSave(),
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 24),
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              fillColor: Colors.transparent,
              hintText: 'Not başlığı…',
              contentPadding: EdgeInsets.zero,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 4),
          Text(
            _formatDate(note.updatedAt),
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: colors.border),
          const SizedBox(height: 16),

          // ── Content Field ──
          Expanded(
            child: TextField(
              controller: _contentController,
              onChanged: (_) => _scheduleSave(),
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontSize: 15, height: 1.7),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                hintText: 'Yazmaya başlayın…',
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, NoteAppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note_rounded, size: 56, color: colors.textMuted),
          const SizedBox(height: 16),
          Text(
            'Not seçilmedi',
            style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            'Sol panelden bir not seçin veya yeni bir not oluşturun.',
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  // ── Debounced Autosave (700ms) ──

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 700), _performSave);
  }

  void _flushSave() {
    if (_saveTimer?.isActive ?? false) {
      _saveTimer!.cancel();
      _performSave();
    }
  }

  void _performSave() {
    if (_loadedNoteId == null) return;
    ref.read(notesProvider.notifier).updateNote(
          _loadedNoteId!,
          title: _titleController.text,
          content: _contentController.text,
        );
  }

  String _formatDate(int ts) {
    final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
