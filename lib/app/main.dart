import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/widgets/app_shell.dart';
import '../providers/settings_provider.dart';
import '../core/theme_definitions.dart';

class NoteApp extends ConsumerWidget {
  const NoteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final themeData = AppThemes.resolve(settings.themeId);

    return MaterialApp(
      title: 'Note App',
      debugShowCheckedModeBanner: false,
      theme: themeData,
      home: const AppShell(),
    );
  }
}
