import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notes_list.dart';
import '../screens/settings_screen.dart';
import '../../providers/notes_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/settings_provider.dart';
import '../../providers/groups_provider.dart';
import '../../models/app_settings.dart';
import '../../models/group.dart';
import '../../core/theme_definitions.dart';

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({super.key});

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _groupsScrollController = ScrollController();

  @override
  void dispose() {
    _searchController.dispose();
    _groupsScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<NoteAppColors>()!;
    final dbState = ref.watch(databaseProvider);
    final workspaceState = ref.watch(workspaceProvider);
    final manifest = workspaceState.manifest;
    final settings = ref.watch(settingsProvider);
    final groupsState = ref.watch(groupsProvider);

    String activeLabel = 'Veritabanı yok';
    if (manifest != null && dbState.activeDbName != null) {
      final activeDbInfo = manifest.databases
          .where((db) => db.name == dbState.activeDbName)
          .toList();
      if (activeDbInfo.isNotEmpty) {
        activeLabel = activeDbInfo.first.label;
      } else {
        activeLabel = dbState.activeDbName!;
      }
    }

    return Container(
      width: 300,
      color: colors.sidebarBg,
      child: Column(
        children: [
          // ── App Title ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Row(
              children: [
                Icon(Icons.note_alt_rounded, color: colors.primary, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Note App',
                  style: theme.textTheme.headlineMedium?.copyWith(fontSize: 18),
                ),
                const Spacer(),
                Text(
                  activeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Divider(height: 24, color: colors.border),
          ),

          // ── New Note Button ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: dbState.isConnected
                    ? () => ref.read(notesProvider.notifier).createNote()
                    : null,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Yeni Not'),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ── Search Field ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Notlarda ara…',
                prefixIcon: Icon(Icons.search_rounded, size: 18),
                isDense: true,
              ),
              style: theme.textTheme.bodyMedium,
              onChanged: (_) => setState(() {}),
            ),
          ),

          const SizedBox(height: 8),

          // ── Sort Selector ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                color: colors.card,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.border, width: 1),
              ),
              child: Row(
                children: [
                  _sortTab(colors, 'A-Z', AppSortMode.alphabetical,
                      settings.sortMode),
                  _sortTab(colors, 'Tarih', AppSortMode.updatedAt,
                      settings.sortMode),
                  _sortTab(
                      colors, 'Özel', AppSortMode.custom, settings.sortMode),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Groups Section (scrollable) ──
          if (dbState.isConnected) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildGroupsBar(context, theme, colors, groupsState),
            ),
            const SizedBox(height: 4),
          ],

          // ── Notes List ──
          Expanded(
            child: NotesList(
              searchQuery: _searchController.text,
              sortMode: settings.sortMode,
              groups: groupsState.groups,
            ),
          ),

          // ── Settings Button ──
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _openSettings(context),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    children: [
                      Icon(Icons.settings_rounded,
                          size: 18, color: colors.textSecondary),
                      const SizedBox(width: 12),
                      Text('Ayarlar', style: theme.textTheme.labelMedium),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Groups bar: horizontal scroll with mouse wheel support.
  Widget _buildGroupsBar(BuildContext context, ThemeData theme,
      NoteAppColors colors, GroupsState groupsState) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: SizedBox(
        height: 42, // increased height to accommodate thinner scrollbar nicely
        child: Listener(
          // Translate vertical mouse wheel into horizontal scroll for the group bar.
          onPointerSignal: (event) {
            if (event is PointerScrollEvent) {
              _groupsScrollController.jumpTo(
                (_groupsScrollController.offset + event.scrollDelta.dy).clamp(
                    0.0, _groupsScrollController.position.maxScrollExtent),
              );
            }
          },
          child: RawScrollbar(
            controller: _groupsScrollController,
            thumbVisibility: true,
            trackVisibility: false,
            thickness: 4.0,
            radius: const Radius.circular(2),
            thumbColor: colors.textMuted.withOpacity(0.6),
            padding: const EdgeInsets.only(top: 36), // push scrollbar down
            child: ListView(
              controller: _groupsScrollController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              padding: const EdgeInsets.only(
                  bottom: 12), // keeps chips well above scrollbar
              children: [
                // "All" chip
                _groupChip(
                  colors,
                  label: 'Tümü',
                  chipColor: colors.primary,
                  isActive: groupsState.activeGroupId == null,
                  onTap: () =>
                      ref.read(groupsProvider.notifier).setFilter(null),
                ),
                const SizedBox(width: 4),
                // Group chips
                ...groupsState.groups.map((g) => Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: _groupChip(
                        colors,
                        label: g.name,
                        chipColor: _parseColor(g.color),
                        isActive: groupsState.activeGroupId == g.id,
                        onTap: () =>
                            ref.read(groupsProvider.notifier).setFilter(g.id),
                        onSecondary: (pos) =>
                            _showGroupContextMenu(context, pos, g),
                      ),
                    )),
                // + button (always reachable at the end of scroll)
                GestureDetector(
                  onTap: () => _showCreateGroupDialog(context),
                  child: Container(
                    height: 26,
                    width: 26,
                    margin: const EdgeInsets.only(top: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: colors.border),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(Icons.add, size: 14, color: colors.textMuted),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _groupChip(
    NoteAppColors colors, {
    required String label,
    required Color chipColor,
    required bool isActive,
    required VoidCallback onTap,
    void Function(Offset)? onSecondary,
  }) {
    return GestureDetector(
      onTap: onTap,
      onSecondaryTapUp: onSecondary != null
          ? (details) => onSecondary(details.globalPosition)
          : null,
      child: Container(
        height: 26,
        margin: const EdgeInsets.only(top: 2),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isActive ? chipColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isActive ? chipColor : colors.border,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              Container(
                width: 7,
                height: 7,
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: chipColor,
                  shape: BoxShape.circle,
                ),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? Colors.white : colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupContextMenu(
      BuildContext context, Offset position, Group group) {
    final colors = Theme.of(context).extension<NoteAppColors>()!;
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          position.dx, position.dy, position.dx + 1, position.dy + 1),
      items: [
        PopupMenuItem(
          value: 'rename',
          child: Row(
            children: [
              Icon(Icons.edit_rounded, size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              const Text('Yeniden Adlandır'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'color',
          child: Row(
            children: [
              Icon(Icons.palette_rounded,
                  size: 16, color: colors.textSecondary),
              const SizedBox(width: 10),
              const Text('Renk Değiştir'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
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
          _showRenameGroupDialog(context, group);
          break;
        case 'color':
          _showColorPickerDialog(context, group);
          break;
        case 'delete':
          _confirmDeleteGroup(context, group);
          break;
      }
    });
  }

  void _showCreateGroupDialog(BuildContext context) {
    final controller = TextEditingController();
    String selectedColor = GroupColors.defaultColor;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: const Text('Yeni Grup'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Grup adı'),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: GroupColors.palette.map((hex) {
                    final isSelected = hex == selectedColor;
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedColor = hex),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _parseColor(hex),
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('İptal')),
              TextButton(
                onPressed: () {
                  final name = controller.text.trim();
                  if (name.isNotEmpty) {
                    ref
                        .read(groupsProvider.notifier)
                        .createGroup(name, selectedColor);
                    ref.read(notesProvider.notifier).reload();
                  }
                  Navigator.pop(ctx);
                },
                child: const Text('Oluştur'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRenameGroupDialog(BuildContext context, Group group) {
    final controller = TextEditingController(text: group.name);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grubu Yeniden Adlandır'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                ref.read(groupsProvider.notifier).renameGroup(group.id!, name);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog(BuildContext context, Group group) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renk Seç'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: GroupColors.palette.map((hex) {
            return GestureDetector(
              onTap: () {
                ref
                    .read(groupsProvider.notifier)
                    .updateGroupColor(group.id!, hex);
                ref.read(notesProvider.notifier).reload();
                Navigator.pop(ctx);
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _parseColor(hex),
                  shape: BoxShape.circle,
                  border: hex == group.color
                      ? Border.all(color: Colors.white, width: 2.5)
                      : null,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _confirmDeleteGroup(BuildContext context, Group group) {
    final colors = Theme.of(context).extension<NoteAppColors>()!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Grubu Sil'),
        content: Text('"${group.name}" grubu silinecek. Notlar silinmeyecek.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () {
              ref.read(groupsProvider.notifier).deleteGroup(group.id!);
              ref.read(notesProvider.notifier).reload();
              Navigator.pop(ctx);
            },
            child: Text('Sil', style: TextStyle(color: colors.deleteColor)),
          ),
        ],
      ),
    );
  }

  Widget _sortTab(NoteAppColors colors, String label, AppSortMode mode,
      AppSortMode current) {
    final isActive = mode == current;
    return Expanded(
      child: GestureDetector(
        onTap: () => ref.read(settingsProvider.notifier).setSortMode(mode),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? colors.sidebarBg : colors.textMuted,
            ),
          ),
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    showDialog(context: context, builder: (_) => const SettingsDialog());
  }

  static Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
