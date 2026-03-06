import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/notes_provider.dart';
import '../../models/note.dart';
import '../../models/app_settings.dart';
import '../../core/theme_definitions.dart';

class NotesList extends ConsumerWidget {
  final String searchQuery;
  final AppSortMode sortMode;

  const NotesList({
    super.key,
    this.searchQuery = '',
    this.sortMode = AppSortMode.alphabetical,
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
        return _NoteItem(
          key: ValueKey(note.id),
          note: note,
          isSelected: isSelected,
          onTap: () => ref.read(notesProvider.notifier).selectNote(note.id),
          onDelete: () => _confirmDelete(context, ref, note),
          onRename: () => _showRenameDialog(context, ref, note),
          onDuplicate: () =>
              ref.read(notesProvider.notifier).duplicateNote(note.id!),
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
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final colors = Theme.of(context).extension<NoteAppColors>();
            return Material(
              color: colors?.card ?? Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              elevation: 4,
              child: child,
            );
          },
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
        return _NoteItem(
          key: ValueKey(note.id),
          note: note,
          isSelected: isSelected,
          onTap: () => ref.read(notesProvider.notifier).selectNote(note.id),
          onDelete: () => _confirmDelete(context, ref, note),
          onRename: () => _showRenameDialog(context, ref, note),
          onDuplicate: () =>
              ref.read(notesProvider.notifier).duplicateNote(note.id!),
          draggable: true,
          dragIndex: index,
        );
      },
    );
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
              Text(
                '"Yeni Not" ile başlayın',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
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
              child: const Text('İptal'),
            ),
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
          decoration: const InputDecoration(hintText: 'Yeni başlık'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              final newTitle = controller.text.trim();
              if (newTitle.isNotEmpty) {
                ref.read(notesProvider.notifier).renameNote(note.id!, newTitle);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  AnimatedBuilder helper (for proxy decorator)
// ─────────────────────────────────────────────

class AnimatedBuilder extends StatelessWidget {
  final Animation<double> animation;
  final Widget Function(BuildContext, Widget?) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required this.animation,
    required this.builder,
    this.child,
  });

  @override
  Widget build(BuildContext context) => builder(context, child);
}

// ─────────────────────────────────────────────
//  Note Item with context menu
// ─────────────────────────────────────────────

class _NoteItem extends StatefulWidget {
  final Note note;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onDuplicate;
  final bool draggable;
  final int? dragIndex;

  const _NoteItem({
    super.key,
    required this.note,
    required this.isSelected,
    required this.onTap,
    required this.onDelete,
    required this.onRename,
    required this.onDuplicate,
    this.draggable = false,
    this.dragIndex,
  });

  @override
  State<_NoteItem> createState() => _NoteItemState();
}

class _NoteItemState extends State<_NoteItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NoteAppColors>()!;
    final updatedAt =
        DateTime.fromMillisecondsSinceEpoch(widget.note.updatedAt * 1000);
    final timeStr = _formatTime(updatedAt);

    Widget item = Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onSecondaryTapUp: (details) =>
              _showContextMenu(context, details.globalPosition),
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
                  ? Border.all(color: colors.primary, width: 1)
                  : null,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: widget.onTap,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    if (widget.draggable)
                      ReorderableDragStartListener(
                        index: widget.dragIndex!,
                        child: MouseRegion(
                          cursor: SystemMouseCursors.grab,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(Icons.drag_indicator_rounded,
                                size: 16, color: colors.textMuted),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
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
                          const SizedBox(height: 2),
                          Text(
                            timeStr,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (_hovering || widget.isSelected)
                      InkWell(
                        borderRadius: BorderRadius.circular(6),
                        onTap: widget.onDelete,
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            size: 16,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    return item;
  }

  void _showContextMenu(BuildContext context, Offset position) {
    final colors = Theme.of(context).extension<NoteAppColors>()!;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem<String>(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              const Text('Yeniden Adlandır'),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'duplicate',
          child: Row(
            children: [
              Icon(Icons.copy_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              const Text('Kopyala'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'group',
          child: Row(
            children: [
              Icon(Icons.folder_outlined,
                  size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              const Text('Gruba Ekle'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline_rounded,
                  size: 16, color: colors.deleteColor),
              const SizedBox(width: 10),
              Text('Sil', style: TextStyle(color: colors.deleteColor)),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value == null || !context.mounted) return;
      switch (value) {
        case 'rename':
          widget.onRename();
          break;
        case 'duplicate':
          widget.onDuplicate();
          break;
        case 'group':
          _showGroupPlaceholder(context);
          break;
        case 'delete':
          widget.onDelete();
          break;
      }
    });
  }

  void _showGroupPlaceholder(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gruba Ekle'),
        content: const Text(
            'Grup sistemi henüz uygulanmadı. Bu özellik gelecekte eklenecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Tamam')),
        ],
      ),
    );
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
