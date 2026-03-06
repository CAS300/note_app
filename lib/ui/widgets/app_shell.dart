import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'app_sidebar.dart';
import 'main_editor_panel.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/database_provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme_definitions.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final workspaceState = ref.watch(workspaceProvider);
    final hasWorkspace =
        workspaceState.path != null && workspaceState.manifest != null;

    // Auto-connect to active DB once workspace is loaded
    if (hasWorkspace && !_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Hydrate settings from manifest
        ref.read(settingsProvider.notifier).loadFromManifest();

        final manifest = workspaceState.manifest!;
        if (manifest.activeDb != null) {
          ref.read(databaseProvider.notifier).connect(
                workspaceState.path!,
                manifest.activeDb!,
              );
        }
      });
    }

    final colors = Theme.of(context).extension<NoteAppColors>();

    return Scaffold(
      body: hasWorkspace
          ? Row(
              children: [
                const AppSidebar(),
                Container(
                    width: 1,
                    color: colors?.border ?? Theme.of(context).dividerColor),
                const Expanded(child: MainEditorPanel()),
              ],
            )
          : _buildNoWorkspaceState(context),
    );
  }

  Widget _buildNoWorkspaceState(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open_rounded,
              size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'Çalışma alanı seçilmedi',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Başlamak için bir çalışma alanı klasörü seçin.',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openWorkspacePicker(),
            icon: const Icon(Icons.folder_outlined, size: 18),
            label: const Text('Klasör Seç'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWorkspacePicker() async {
    final picked = await FilePicker.platform.getDirectoryPath();
    if (picked != null) {
      await ref.read(workspaceProvider.notifier).loadWorkspace(picked);
      // Hydrate settings after loading workspace
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
}
