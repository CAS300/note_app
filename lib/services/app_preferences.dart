import 'package:shared_preferences/shared_preferences.dart';

/// App-level local preferences stored via shared_preferences.
/// These are device-specific, NOT workspace-specific.
class AppPreferences {
  static const _keyLastWorkspacePath = 'last_workspace_path';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  String? get lastWorkspacePath => _prefs?.getString(_keyLastWorkspacePath);

  Future<void> setLastWorkspacePath(String path) async {
    await _prefs?.setString(_keyLastWorkspacePath, path);
  }

  Future<void> clearLastWorkspacePath() async {
    await _prefs?.remove(_keyLastWorkspacePath);
  }
}
