/// Identifies which app theme is active.
enum AppThemeId {
  defaultTheme,
  terminalGreen,
}

/// Identifies how notes should be sorted in the sidebar.
enum AppSortMode {
  alphabetical,
  updatedAt,
  custom,
}

/// Local app settings persisted inside the workspace manifest `settings` map.
class AppSettings {
  final AppThemeId themeId;
  final AppSortMode sortMode;
  final double editorFontSize;

  const AppSettings({
    this.themeId = AppThemeId.defaultTheme,
    this.sortMode = AppSortMode.alphabetical,
    this.editorFontSize = 12.0,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      themeId: _parseTheme(map['theme'] as String?),
      sortMode: _parseSortMode(map['sort_mode'] as String?),
      editorFontSize: _parseFontSize(map['editor_font_size']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': themeId.name,
      'sort_mode': sortMode.name,
      'editor_font_size': editorFontSize,
    };
  }

  AppSettings copyWith({
    AppThemeId? themeId,
    AppSortMode? sortMode,
    double? editorFontSize,
  }) {
    return AppSettings(
      themeId: themeId ?? this.themeId,
      sortMode: sortMode ?? this.sortMode,
      editorFontSize: editorFontSize ?? this.editorFontSize,
    );
  }

  static AppThemeId _parseTheme(String? value) {
    if (value == null) return AppThemeId.defaultTheme;
    return AppThemeId.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppThemeId.defaultTheme,
    );
  }

  static AppSortMode _parseSortMode(String? value) {
    if (value == null) return AppSortMode.alphabetical;
    return AppSortMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => AppSortMode.alphabetical,
    );
  }

  static double _parseFontSize(dynamic value) {
    if (value == null) return 12.0;
    if (value is int) return value.toDouble();
    if (value is double) return value.clamp(10.0, 20.0);
    return 12.0;
  }
}
