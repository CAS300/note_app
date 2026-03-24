import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'markdown_text_controller.dart';
import '../../providers/notes_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/groups_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/note.dart';
import '../../models/group.dart';
import '../../core/theme_definitions.dart';

class MainEditorPanel extends ConsumerStatefulWidget {
  const MainEditorPanel({super.key});

  @override
  ConsumerState<MainEditorPanel> createState() => _MainEditorPanelState();
}

class _MainEditorPanelState extends ConsumerState<MainEditorPanel> {
  final TextEditingController _titleController = TextEditingController();
  late MarkdownTextController _contentController;
  final FocusNode _contentFocus = FocusNode();
  
  // Search related state
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  Timer? _saveTimer;
  int? _loadedNoteId;
  bool _emojiOpen = false;

  @override
  void initState() {
    super.initState();
    _contentController = MarkdownTextController(
      baseFontSize: 12.0,
      textColor: Colors.white,
      highlightColor: Colors.blue,
      mutedColor: Colors.grey,
    );
  }

  @override
  void dispose() {
    _flushSave();
    _titleController.dispose();
    _contentController.dispose();
    _contentFocus.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
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
    final groupsState = ref.watch(groupsProvider);
    final settings = ref.watch(settingsProvider);

    // Sync controllers when a different note is selected
    if (note != null && note.id != _loadedNoteId) {
      _flushSave();
      _loadedNoteId = note.id;
      _titleController.text = note.title;
      _contentController.text = note.content;
      _emojiOpen = false;
      _showSearch = false;
      _searchController.clear();
      _contentController.searchQuery = null;
    } else if (note == null && _loadedNoteId != null) {
      _flushSave();
      _loadedNoteId = null;
      _titleController.clear();
      _contentController.clear();
      _emojiOpen = false;
      _showSearch = false;
      _searchController.clear();
      _contentController.searchQuery = null;
    }

    final noteGroups = note != null 
        ? note.groupIds.map((id) => groupsState.groupById(id)).whereType<Group>().toList() 
        : <Group>[];

    return Column(
      children: [
        _buildTopBar(theme, colors, manifest, dbState),
        Container(height: 1, color: colors.border),
        Expanded(
          child: note != null
              ? _buildEditor(
                  theme, colors, note, noteGroups, settings.editorFontSize)
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
                    style: theme.textTheme.labelMedium
                        ?.copyWith(color: colors.textPrimary),
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

  Widget _buildEditor(ThemeData theme, NoteAppColors colors, Note note,
      List<Group> noteGroups, double fontSize) {
    // Sync controller formatting properties with current theme/settings
    _contentController.baseFontSize = fontSize;
    _contentController.textColor = colors.textSecondary;
    _contentController.highlightColor = colors.primary;
    _contentController.mutedColor = colors.textMuted;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final isControlOrCmd = HardwareKeyboard.instance.isControlPressed || HardwareKeyboard.instance.isMetaPressed;
          if (event.logicalKey == LogicalKeyboardKey.keyF && isControlOrCmd) {
            setState(() => _showSearch = true);
            _searchFocus.requestFocus();
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.escape && _showSearch) {
            setState(() {
              _showSearch = false;
              _searchController.clear();
              _contentController.searchQuery = null;
            });
            _contentFocus.requestFocus();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        // ── Title & Group chip ──
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 24, 40, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _titleController,
                      onChanged: (_) => _scheduleSave(),
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontSize: 24),
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
                  ),
                  if (noteGroups.isNotEmpty)
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: noteGroups.map((g) => Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: _buildGroupChip(colors, g),
                      )).toList(),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(_formatDate(note.updatedAt),
                  style: theme.textTheme.bodySmall),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // ── Toolbar ──
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Row(
            children: [
              _buildToolbar(theme, colors),
              const Spacer(),
              if (!_showSearch)
                IconButton(
                  icon: Icon(Icons.search_rounded, size: 18, color: colors.textMuted),
                  tooltip: 'Notta Ara (Ctrl+F)',
                  onPressed: () {
                    setState(() => _showSearch = true);
                    _searchFocus.requestFocus();
                  },
                ),
            ],
          ),
        ),

        if (_showSearch)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.primary.withOpacity(0.5)),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Icon(Icons.search_rounded, size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      style: theme.textTheme.bodyMedium,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        hintText: 'Kelime ara...',
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (val) {
                        setState(() {
                          _contentController.searchQuery = val;
                        });
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, size: 16, color: colors.textMuted),
                    onPressed: () {
                      setState(() {
                        _showSearch = false;
                        _searchController.clear();
                        _contentController.searchQuery = null;
                      });
                      _contentFocus.requestFocus();
                    },
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 8),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Container(height: 1, color: colors.border),
        ),

        const SizedBox(height: 8),

        // ── Content Field ──
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: TextField(
              controller: _contentController,
              focusNode: _contentFocus,
              onChanged: (_) => _scheduleSave(),
              style: TextStyle(
                fontFamily: 'Segoe UI',
                fontFamilyFallback: const [
                  'Inter',
                  'Roboto',
                  'Helvetica Neue',
                  'Arial',
                  'sans-serif'
                ],
                fontSize: fontSize,
                height: 1.6,
                color: colors.textSecondary,
              ),
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
        ),

        // ── Emoji Picker Panel ──
        if (_emojiOpen)
          SizedBox(
            height: 260,
            child: EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _insertAtCursor(emoji.emoji);
                _scheduleSave();
              },
              config: Config(
                height: 260,
                emojiViewConfig: EmojiViewConfig(
                  columns: 8,
                  emojiSizeMax: 24,
                  backgroundColor: colors.card,
                ),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: colors.card,
                  indicatorColor: colors.primary,
                  iconColorSelected: colors.primary,
                  iconColor: colors.textMuted,
                ),
                searchViewConfig: SearchViewConfig(
                  backgroundColor: colors.card,
                  hintText: 'Emoji ara…',
                ),
                bottomActionBarConfig: const BottomActionBarConfig(
                  enabled: false,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupChip(NoteAppColors colors, dynamic group) {
    final hex = (group.color as String).replaceFirst('#', '');
    final gc = Color(int.parse('FF$hex', radix: 16));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: gc.withAlpha(40),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: gc.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: gc, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(group.name as String,
              style: TextStyle(
                  fontSize: 11, color: gc, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildToolbar(ThemeData theme, NoteAppColors colors) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _toolBtn(colors, Icons.emoji_emotions_outlined, 'Emoji', () {
            setState(() => _emojiOpen = !_emojiOpen);
          }),
          _divider(colors),
          _toolBtn(colors, Icons.looks_one_outlined, 'H1',
              () => _applyLinePrefix('# ')),
          _toolBtn(colors, Icons.looks_two_outlined, 'H2',
              () => _applyLinePrefix('## ')),
          _toolBtn(colors, Icons.looks_3_outlined, 'H3',
              () => _applyLinePrefix('### ')),
          _divider(colors),
          _toolBtn(
              colors, Icons.check_box_outlined, 'Checkbox', _toggleCheckbox),
          _toolBtn(colors, Icons.format_bold_rounded, 'Kalın', _wrapBold),
        ],
      ),
    );
  }

  Widget _toolBtn(
      NoteAppColors colors, IconData icon, String tooltip, VoidCallback onTap) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(icon, size: 18, color: colors.textSecondary),
        ),
      ),
    );
  }

  Widget _divider(NoteAppColors colors) {
    return Container(width: 1, height: 18, color: colors.border);
  }

  // ══════════════════════════════════════════════
  //  ROBUST TEXT MANIPULATION HELPERS
  // ══════════════════════════════════════════════

  /// Regex that matches any known prefix at the start of a line.
  static final _knownPrefixRe = RegExp(r'^(#{1,3}\s|- \[[ x]\] )');

  /// Insert text at the current cursor position.
  void _insertAtCursor(String text) {
    final sel = _contentController.selection;
    final cur = sel.isValid ? sel.baseOffset : _contentController.text.length;
    final before = _contentController.text.substring(0, cur);
    final after = _contentController.text.substring(cur);
    _contentController.text = '$before$text$after';
    _contentController.selection =
        TextSelection.collapsed(offset: cur + text.length);
    _contentFocus.requestFocus();
  }

  /// Returns (lineStart, lineEnd) for the line where the cursor currently sits.
  (int, int) _currentLineRange() {
    final text = _contentController.text;
    final sel = _contentController.selection;
    final cursor = sel.isValid ? sel.baseOffset : text.length;

    int lineStart = text.lastIndexOf('\n', cursor > 0 ? cursor - 1 : 0);
    lineStart = lineStart == -1 ? 0 : lineStart + 1;

    int lineEnd = text.indexOf('\n', cursor);
    if (lineEnd == -1) lineEnd = text.length;

    return (lineStart, lineEnd);
  }

  /// Strips all known prefixes (headings, checkboxes) from a line.
  String _stripKnownPrefixes(String line) {
    return line.replaceFirst(_knownPrefixRe, '');
  }

  /// Apply a heading prefix (e.g. "# ", "## ", "### ") to the current line.
  /// Removes any existing heading or checkbox prefix first.
  /// Toggling: if the line already has this exact prefix, just remove it.
  void _applyLinePrefix(String prefix) {
    final text = _contentController.text;
    final (lineStart, lineEnd) = _currentLineRange();
    final line = text.substring(lineStart, lineEnd);

    String newLine;
    if (line.startsWith(prefix)) {
      // Toggle off — remove the prefix.
      newLine = line.substring(prefix.length);
    } else {
      // Strip any existing prefix, then apply the new one.
      newLine = '$prefix${_stripKnownPrefixes(line)}';
    }

    final before = text.substring(0, lineStart);
    final after = text.substring(lineEnd);
    _contentController.text = '$before$newLine$after';

    // Place cursor at end of the new line.
    final newCursor = lineStart + newLine.length;
    _contentController.selection = TextSelection.collapsed(
      offset: newCursor.clamp(0, _contentController.text.length),
    );
    _contentFocus.requestFocus();
    _scheduleSave();
  }

  /// Toggle checkbox prefix on the current line.
  /// Removes heading prefixes first. Toggles between adding/removing "- [ ] ".
  void _toggleCheckbox() {
    final text = _contentController.text;
    final (lineStart, lineEnd) = _currentLineRange();
    final line = text.substring(lineStart, lineEnd);

    String newLine;
    if (line.startsWith('- [ ] ')) {
      // Remove unchecked checkbox.
      newLine = line.substring(6);
    } else if (line.startsWith('- [x] ')) {
      // Remove checked checkbox.
      newLine = line.substring(6);
    } else {
      // Strip any prefix and add checkbox.
      newLine = '- [ ] ${_stripKnownPrefixes(line)}';
    }

    final before = text.substring(0, lineStart);
    final after = text.substring(lineEnd);
    _contentController.text = '$before$newLine$after';

    final newCursor = lineStart + newLine.length;
    _contentController.selection = TextSelection.collapsed(
      offset: newCursor.clamp(0, _contentController.text.length),
    );
    _contentFocus.requestFocus();
    _scheduleSave();
  }

  /// Wrap selected text with bold markers, or insert empty bold markers.
  void _wrapBold() {
    final text = _contentController.text;
    final sel = _contentController.selection;

    if (!sel.isValid || sel.isCollapsed) {
      // No selection — insert **** and place cursor in the middle.
      final cursor = sel.isValid ? sel.baseOffset : text.length;
      final before = text.substring(0, cursor);
      final after = text.substring(cursor);
      _contentController.text = '$before****$after';
      _contentController.selection =
          TextSelection.collapsed(offset: cursor + 2);
      _contentFocus.requestFocus();
      _scheduleSave();
      return;
    }

    // Wrap selected text with **.
    final selected = text.substring(sel.start, sel.end);
    final replacement = '**$selected**';
    final before = text.substring(0, sel.start);
    final after = text.substring(sel.end);
    _contentController.text = '$before$replacement$after';
    // Select the wrapped text (including markers) for visibility.
    _contentController.selection = TextSelection(
      baseOffset: sel.start,
      extentOffset: sel.start + replacement.length,
    );
    _contentFocus.requestFocus();
    _scheduleSave();
  }

  Widget _buildEmptyState(ThemeData theme, NoteAppColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.edit_note_rounded, size: 56, color: colors.textMuted),
          const SizedBox(height: 16),
          Text('Not seçilmedi',
              style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18)),
          const SizedBox(height: 6),
          Text('Sol panelden bir not seçin veya yeni bir not oluşturun.',
              style: theme.textTheme.bodyMedium),
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
