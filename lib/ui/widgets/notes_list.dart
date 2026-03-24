import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notes_provider.dart';
import '../../providers/groups_provider.dart';
import '../../models/note.dart';
import '../../models/group.dart';
import '../../models/app_settings.dart';
import '../../core/theme_definitions.dart';

class NotesList extends ConsumerWidget {
  final String searchQuery;
  final AppSortMode sortMode;
  final List<Group> groups;

  const NotesList({
    super.key,
    this.searchQuery = '',
    this.sortMode = AppSortMode.alphabetical,
    this.groups = const [],
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notesState = ref.watch(notesProvider);
    final notes = _filteredNotes(notesState.notes);

    if (notes.isEmpty) {
      return _buildEmptyState(context);
    }

    final isCustom =
        sortMode == AppSortMode.custom && searchQuery.trim().isEmpty;

    if (isCustom) {
      return _buildReorderableList(context, ref, notes, notesState);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = note.id == notesState.selectedNoteId;
        final groupsForNote = _groupsFor(note);
        return _NoteItem(
          key: ValueKey(note.id),
          note: note,
          groups: groupsForNote,
          isSelected: isSelected,
          onTap: () => _handleTap(context, ref, note),
          onDelete: () => _confirmDelete(context, ref, note),
          onRename: () => _showRenameDialog(context, ref, note),
          onDuplicate: () =>
              ref.read(notesProvider.notifier).duplicateNote(note.id!),
          onGroupAssign: () => _showGroupAssignDialog(context, ref, note),
          onEdit: () => ref.read(notesProvider.notifier).selectNote(note.id),
          onToggleShortcut: () {
            ref.read(notesProvider.notifier).toggleShortcut(note.id!);
          },
        );
      },
    );
  }

  Widget _buildReorderableList(BuildContext context, WidgetRef ref,
      List<Note> notes, NotesState notesState) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      buildDefaultDragHandles: false,
      itemCount: notes.length,
      proxyDecorator: (child, index, animation) {
        return Material(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(8),
          elevation: 4,
          child: child,
        );
      },
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final ids = notes.map((n) => n.id!).toList();
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        ref.read(notesProvider.notifier).reorder(ids);
      },
      itemBuilder: (context, index) {
        final note = notes[index];
        final isSelected = note.id == notesState.selectedNoteId;
        final groupsForNote = _groupsFor(note);
        return _NoteItem(
          key: ValueKey(note.id),
          note: note,
          groups: groupsForNote,
          isSelected: isSelected,
          onTap: () => _handleTap(context, ref, note),
          onDelete: () => _confirmDelete(context, ref, note),
          onRename: () => _showRenameDialog(context, ref, note),
          onDuplicate: () =>
              ref.read(notesProvider.notifier).duplicateNote(note.id!),
          onGroupAssign: () => _showGroupAssignDialog(context, ref, note),
          onEdit: () => ref.read(notesProvider.notifier).selectNote(note.id),
          onToggleShortcut: () {
            ref.read(notesProvider.notifier).toggleShortcut(note.id!);
          },
          draggable: true,
          dragIndex: index,
        );
      },
    );
  }

  /// Central tap handler: shortcut notes copy to clipboard, normal notes select.
  void _handleTap(BuildContext context, WidgetRef ref, Note note) {
    if (note.isShortcut) {
      Clipboard.setData(ClipboardData(text: note.content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kopyalandı'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          width: 140,
        ),
      );
    } else {
      ref.read(notesProvider.notifier).selectNote(note.id);
    }
  }

  List<Group> _groupsFor(Note note) {
    if (note.groupIds.isEmpty) return [];
    return groups.where((g) => note.groupIds.contains(g.id)).toList();
  }

  List<Note> _filteredNotes(List<Note> notes) {
    if (searchQuery.trim().isEmpty) return notes;
    final q = searchQuery.trim().toLowerCase();
    return notes
        .where((n) =>
            n.title.toLowerCase().contains(q) ||
            n.content.toLowerCase().contains(q))
        .toList();
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.sticky_note_2_outlined,
                size: 40, color: theme.colorScheme.outline),
            const SizedBox(height: 12),
            Text(
              searchQuery.isNotEmpty ? 'Sonuç bulunamadı' : 'Henüz not yok',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (searchQuery.isEmpty) ...[
              const SizedBox(height: 4),
              Text('"Yeni Not" ile başlayın',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Note note) {
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<NoteAppColors>();
        return AlertDialog(
          title: const Text('Notu Sil'),
          content: Text('"${note.title}" silinsin mi?'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('İptal')),
            TextButton(
              onPressed: () {
                ref.read(notesProvider.notifier).deleteNote(note.id!);
                Navigator.pop(ctx);
              },
              child: Text('Sil',
                  style: TextStyle(color: colors?.deleteColor ?? Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, Note note) {
    final controller = TextEditingController(text: note.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notu Yeniden Adlandır'),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Yeni başlık')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              final t = controller.text.trim();
              if (t.isNotEmpty) {
                ref.read(notesProvider.notifier).renameNote(note.id!, t);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showGroupAssignDialog(BuildContext context, WidgetRef ref, Note note) {
    final groupsState = ref.read(groupsProvider);
    showDialog(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).extension<NoteAppColors>()!;
        return AlertDialog(
          title: const Text('Gruba Ata'),
          content: SizedBox(
            width: 260,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (note.groupIds.isNotEmpty)
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.close_rounded,
                        size: 16, color: colors.deleteColor),
                    title: Text('Tüm Gruplardan Çıkar',
                        style:
                            TextStyle(fontSize: 13, color: colors.deleteColor)),
                    onTap: () {
                      ref.read(notesProvider.notifier).updateNote(note.id!, groupIds: const []);
                      Navigator.pop(ctx);
                    },
                  ),
                ...groupsState.groups.map((g) {
                  final isActive = note.groupIds.contains(g.id);
                  return ListTile(
                    dense: true,
                    leading: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _parseColor(g.color),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(g.name, style: const TextStyle(fontSize: 13)),
                    trailing: isActive
                        ? Icon(Icons.check_rounded,
                            size: 16, color: colors.primary)
                        : null,
                    onTap: () {
                      final newGroups = List<int>.from(note.groupIds);
                      if (isActive) {
                        newGroups.remove(g.id);
                      } else {
                        newGroups.add(g.id!);
                      }
                      ref.read(notesProvider.notifier).updateNote(note.id!, groupIds: newGroups);
                      Navigator.pop(ctx);
                    },
                  );
                }),
                if (groupsState.groups.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('Henüz grup yok. Kenar çubuğundan oluşturun.',
                        style:
                            TextStyle(fontSize: 12, color: colors.textMuted)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}

// ─────────────────────────────────────────────
//  Note Item with group color accent, shortcut badge, context menu
// ─────────────────────────────────────────────
class _NoteItem extends StatefulWidget {
  final Note note;
  final List<Group> groups;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final VoidCallback onGroupAssign;
  final VoidCallback onEdit;
  final VoidCallback onToggleShortcut;
  final bool draggable;
  final int? dragIndex;

  const _NoteItem({
    super.key,
    required this.note,
    this.groups = const [],
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.onDuplicate,
    required this.onGroupAssign,
    required this.onEdit,
    required this.onToggleShortcut,
    this.draggable = false,
    this.dragIndex,
  });

  @override
  State<_NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends State<_NoteItem> {
  bool _hovering = false;

  Color? get _groupColor {
    if (widget.groups.isEmpty) return null;
    final h = widget.groups.first.color.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NoteAppColors>()!;
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(widget.note.updatedAt * 1000);
    final timeStr = _formatTime(updatedAt);
    final gc = _groupColor;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onSecondaryTapUp: (d) => _showContextMenu(context, d.globalPosition),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? colors.card
                  : _hovering
                      ? Color.lerp(colors.sidebarBg, colors.card, 0.4)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: widget.isSelected
                  ? Border.all(color: gc ?? colors.primary, width: 1)
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onTap,
              child: Row(
                children: [
                  // ── Group accent bar ──
                  if (gc != null)
                    Container(
                      width: 3,
                      height: 44,
                      margin: const EdgeInsets.only(left: 2),
                      decoration: BoxDecoration(
                        color: gc,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  if (widget.draggable)
                    ReorderableDragStartListener(
                      index: widget.dragIndex!,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.grab,
                        child: Padding(
                          padding: EdgeInsets.only(
                              left: gc != null ? 4 : 8, right: 4),
                          child: Icon(Icons.drag_indicator_rounded,
                              size: 16, color: colors.textMuted),
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: widget.draggable ? 0 : (gc != null ? 8 : 12),
                        right: 12,
                        top: 10,
                        bottom: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // ── Shortcut badge ──
                              if (widget.note.isShortcut)
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: Icon(Icons.bolt_rounded,
                                      size: 14, color: colors.highlight),
                                ),
                              Expanded(
                                child: Text(
                                  widget.note.title.isEmpty
                                      ? 'Başlıksız Not'
                                      : widget.note.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontSize: 14,
                                    fontWeight: widget.isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.groups.isNotEmpty)
                                Row(
                                  children: widget.groups.map((g) {
                                    final gColorStr = g.color.replaceFirst('#', '');
                                    final gColor = Color(int.parse('FF$gColorStr', radix: 16));
                                    return Container(
                                      margin: const EdgeInsets.only(left: 6),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: gColor.withAlpha(40),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        g.name,
                                        style: TextStyle(
                                            fontSize: 9,
                                            color: gColor,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    );
                                  }).toList(),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(timeStr,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                  if (_hovering || widget.isSelected)
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: widget.onDelete,
                      child: Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: Icon(Icons.delete_outline_rounded,
                            size: 16, color: colors.textMuted),
                      ),
                    ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final colors = Theme.of(context).extension<NoteAppColors>()!;
    final isShortcut = widget.note.isShortcut;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(
            value: 'edit',
            child: Row(children: [
              Icon(Icons.edit_note_rounded,
                  size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              const Text('Düzenle'),
            ])),
        PopupMenuItem(
          value: 'shortcut',
          child: Row(children: [
            Icon(
              isShortcut ? Icons.bolt_outlined : Icons.bolt_rounded,
              size: 16,
              color: colors.textSecondary,
            ),
            const SizedBox(width: 10),
            Text(isShortcut ? 'Kısayoldan Çıkar' : 'Kısayol Olarak Ayarla'),
          ]),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
            value: 'rename',
            child: Row(children: [
              Icon(Icons.edit_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              const Text('Yeniden Adlandır'),
            ])),
        PopupMenuItem(
            value: 'duplicate',
            child: Row(children: [
              Icon(Icons.copy_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              const Text('Kopyala'),
            ])),
        const PopupMenuDivider(),
        PopupMenuItem(
            value: 'group',
            child: Row(children: [
              Icon(Icons.folder_outlined,
                  size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              const Text('Gruba Ata'),
            ])),
        const PopupMenuDivider(),
        PopupMenuItem(
            value: 'delete',
            child: Row(children: [
              Icon(Icons.delete_outline_rounded,
                  size: 16, color: colors.deleteColor),
              const SizedBox(width: 10),
              Text('Sil', style: TextStyle(color: colors.deleteColor)),
            ])),
      ],
    ).then((value) {
      if (value == null || !context.mounted) return;
      switch (value) {
        case 'edit':
          widget.onEdit();
          break;
        case 'shortcut':
          widget.onToggleShortcut();
          break;
        case 'rename':
          widget.onRename();
          break;
        case 'duplicate':
          widget.onDuplicate();
          break;
        case 'group':
          widget.onGroupAssign();
          break;
        case 'delete':
          widget.onDelete();
          break;
      }
    });
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'az önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
