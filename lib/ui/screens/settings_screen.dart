import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/workspace_provider.dart';
import '../../providers/database_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickWorkspace(BuildContext context, WidgetRef ref) async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      await ref.read(workspaceProvider.notifier).loadWorkspace(selectedDirectory);
      final manifest = ref.read(workspaceProvider).manifest;
      if (manifest != null && manifest.activeDb != null) {
        await ref.read(databaseProvider.notifier).switchDatabase(manifest.activeDb!);
      }
    }
  }

  Future<void> _createNewDatabase(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Database'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter name (e.g. work)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Create')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final error = await ref.read(databaseProvider.notifier).createNewDatabase(result);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database created successfully.')));
      }
    }
  }

  Future<void> _addExistingDatabase(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Existing Database'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter filename (e.g. archive.db)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Add')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      final error = await ref.read(databaseProvider.notifier).addExistingDatabase(result);
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Database added successfully.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceState = ref.watch(workspaceProvider);

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        ElevatedButton(
          onPressed: () => _pickWorkspace(context, ref),
          child: const Text('Choose Workspace Folder'),
        ),
        if (workspaceState.path != null) ...[
          const SizedBox(height: 16),
          Text('Active Workspace: \${workspaceState.path}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              ElevatedButton(
                onPressed: () => _createNewDatabase(context, ref),
                child: const Text('Create New Database'),
              ),
              ElevatedButton(
                onPressed: () => _addExistingDatabase(context, ref),
                child: const Text('Add Existing Database'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('Databases:', style: TextStyle(fontWeight: FontWeight.bold)),
          if (workspaceState.manifest != null)
            ...workspaceState.manifest!.databases.map((db) => ListTile(
              title: Text(db.name),
              subtitle: Text(db.label),
            )),
        ]
      ],
    );
  }
}
