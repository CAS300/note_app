import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notes_list.dart';
import '../screens/settings_screen.dart';
import '../../providers/notes_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/app_settings.dart';
import '../../core/theme_definitions.dart';

class AppSidebar extends ConsumerStatefulWidget {
  const AppSidebar({super.key});

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
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

    // Find label for the active DB
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
              onChanged: (_) {
                setState(() {});
              },
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
                  _sortTab(context, colors, 'A-Z', AppSortMode.alphabetical,
                      settings.sortMode),
                  _sortTab(context, colors, 'Tarih', AppSortMode.updatedAt,
                      settings.sortMode),
                  _sortTab(context, colors, 'Özel', AppSortMode.custom,
                      settings.sortMode),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Notes List ──
          Expanded(
            child: NotesList(
              searchQuery: _searchController.text,
              sortMode: settings.sortMode,
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

  Widget _sortTab(BuildContext context, NoteAppColors colors, String label,
      AppSortMode mode, AppSortMode current) {
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
    showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }
}
