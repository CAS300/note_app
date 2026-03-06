import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import 'workspace_provider.dart';

/// Provides [AppSettings] derived from the workspace manifest settings map
/// and methods to update individual settings.
class SettingsNotifier extends StateNotifier<AppSettings> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const AppSettings());

  /// Call after workspace loads to hydrate settings from the manifest.
  void loadFromManifest() {
    final ws = _ref.read(workspaceProvider);
    if (ws.manifest == null) return;
    state = AppSettings.fromMap(ws.manifest!.settings);
  }

  Future<void> setTheme(AppThemeId themeId) async {
    state = state.copyWith(themeId: themeId);
    await _persist();
  }

  Future<void> setSortMode(AppSortMode mode) async {
    state = state.copyWith(sortMode: mode);
    await _persist();
  }

  Future<void> setEditorFontSize(double size) async {
    state = state.copyWith(editorFontSize: size.clamp(10.0, 20.0));
    await _persist();
  }

  /// Persist current settings back into the workspace manifest.
  Future<void> _persist() async {
    final ws = _ref.read(workspaceProvider);
    if (ws.manifest == null) return;

    // Merge our settings into the existing settings map (preserves other keys).
    final merged = Map<String, dynamic>.from(ws.manifest!.settings)
      ..addAll(state.toMap());

    final updated = ws.manifest!.copyWith(settings: merged);
    await _ref.read(workspaceProvider.notifier).updateManifest(updated);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier(ref);
});
