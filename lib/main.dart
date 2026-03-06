import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/main.dart';
import 'services/app_preferences.dart';
import 'providers/app_preferences_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize app-level preferences (device-local, not workspace-level).
  final prefs = AppPreferences();
  await prefs.init();

  runApp(
    ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const NoteApp(),
    ),
  );
}
