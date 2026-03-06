import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../models/app_settings.dart';
import '../../core/theme_definitions.dart';

/// Desktop-friendly settings dialog opened from the sidebar.
class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.extension<NoteAppColors>()!;
    final workspaceState = ref.watch(workspaceProvider);
    final dbState = ref.watch(databaseProvider);
    final manifest = workspaceState.manifest;
    final databases = manifest?.databases ?? [];
    final settings = ref.watch(settingsProvider);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 650),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Scaffold(
            backgroundColor: colors.card,
            appBar: AppBar(
              backgroundColor: colors.card,
              elevation: 0,
              leading: const SizedBox(),
              leadingWidth: 0,
              centerTitle: false,
              title: Row(
                children: [
                  Icon(Icons.settings_rounded, size: 20, color: colors.primary),
                  const SizedBox(width: 10),
                  Text('Ayarlar',
                      style: theme.textTheme.headlineMedium
                          ?.copyWith(fontSize: 18)),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                // ── Appearance ──
                _sectionTitle(theme, colors, 'Görünüm'),
                const SizedBox(height: 8),
                _settingsCard(
                  colors,
                  children: [
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('Tema',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: colors.sidebarBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<AppThemeId>(
                                value: settings.themeId,
                                isExpanded: true,
                                dropdownColor: colors.card,
                                style: theme.textTheme.bodyMedium,
                                items: AppThemeId.values.map((id) {
                                  return DropdownMenuItem(
                                    value: id,
                                    child: Text(AppThemes.label(id)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    ref
                                        .read(settingsProvider.notifier)
                                        .setTheme(value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text('Sıralama',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600)),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: colors.sidebarBg,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: colors.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<AppSortMode>(
                                value: settings.sortMode,
                                isExpanded: true,
                                dropdownColor: colors.card,
                                style: theme.textTheme.bodyMedium,
                                items: const [
                                  DropdownMenuItem(
                                    value: AppSortMode.alphabetical,
                                    child: Text('Alfabetik (A-Z)'),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSortMode.updatedAt,
                                    child: Text('Son Güncelleme'),
                                  ),
                                  DropdownMenuItem(
                                    value: AppSortMode.custom,
                                    child: Text('Özel Sıralama'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    ref
                                        .read(settingsProvider.notifier)
                                        .setSortMode(value);
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Workspace Section ──
                _sectionTitle(theme, colors, 'Çalışma Alanı'),
                const SizedBox(height: 8),
                _settingsCard(
                  colors,
                  children: [
                    _infoRow(
                        theme, 'Konum', workspaceState.path ?? 'Seçilmedi'),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _pickWorkspace(context, ref),
                        icon: const Icon(Icons.folder_open_rounded, size: 16),
                        label: const Text('Klasör Değiştir'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: colors.textPrimary,
                          side: BorderSide(color: colors.border),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Databases Section ──
                _sectionTitle(theme, colors, 'Veritabanları'),
                const SizedBox(height: 8),
                _settingsCard(
                  colors,
                  children: [
                    if (databases.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Henüz veritabanı yok.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      )
                    else
                      ...databases.map((db) {
                        final isActive = db.name == dbState.activeDbName;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () => ref
                                .read(databaseProvider.notifier)
                                .switchDatabase(db.name),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? colors.border
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isActive
                                        ? Icons.check_circle_rounded
                                        : Icons.circle_outlined,
                                    size: 16,
                                    color: isActive
                                        ? colors.highlight
                                        : colors.textMuted,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          db.label,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(fontSize: 14),
                                        ),
                                        Text(
                                          db.name,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(fontSize: 11),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isActive)
                                    Text('Aktif',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: colors.highlight,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 11,
                                        )),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _createNewDatabase(context, ref),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Yeni Oluştur'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _addExistingDatabase(context, ref),
                            icon:
                                const Icon(Icons.attach_file_rounded, size: 16),
                            label: const Text('Mevcut Ekle'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.textPrimary,
                              side: BorderSide(color: colors.border),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Export Section placeholder ──
                _sectionTitle(theme, colors, 'Dışa Aktarma'),
                const SizedBox(height: 8),
                _settingsCard(
                  colors,
                  children: [
                    _infoRow(
                      theme,
                      'Drive Yolu',
                      (manifest?.settings['drive_export_path'] as String?) ??
                          'Ayarlanmadı',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(ThemeData theme, NoteAppColors colors, String text) {
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        color: colors.primary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _settingsCard(NoteAppColors colors, {required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.sidebarBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ── Actions ──

  Future<void> _pickWorkspace(BuildContext context, WidgetRef ref) async {
    final picked = await FilePicker.platform.getDirectoryPath();
    if (picked != null) {
      await ref.read(workspaceProvider.notifier).loadWorkspace(picked);
      ref.read(settingsProvider.notifier).loadFromManifest();
      final manifest = ref.read(workspaceProvider).manifest;
      if (manifest != null && manifest.activeDb != null) {
        ref.read(databaseProvider.notifier).connect(
              ref.read(workspaceProvider).path!,
              manifest.activeDb!,
            );
      }
    }
  }

  Future<void> _createNewDatabase(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni Veritabanı'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'Etiket (ör. İş, Kişisel)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && context.mounted) {
      final error = await ref
          .read(databaseProvider.notifier)
          .createNewDatabase(result.trim());
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  Future<void> _addExistingDatabase(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mevcut Veritabanı Ekle'),
        content: TextField(
          controller: controller,
          decoration:
              const InputDecoration(hintText: 'Dosya adı (ör. archive.db)'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );

    if (result != null && result.trim().isNotEmpty && context.mounted) {
      final error = await ref
          .read(databaseProvider.notifier)
          .addExistingDatabase(result.trim());
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }
}
