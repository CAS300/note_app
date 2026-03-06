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

  const AppSettings({
    this.themeId = AppThemeId.defaultTheme,
    this.sortMode = AppSortMode.alphabetical,
  });

  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      themeId: _parseTheme(map['theme'] as String?),
      sortMode: _parseSortMode(map['sort_mode'] as String?),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': themeId.name,
      'sort_mode': sortMode.name,
    };
  }

  AppSettings copyWith({AppThemeId? themeId, AppSortMode? sortMode}) {
    return AppSettings(
      themeId: themeId ?? this.themeId,
      sortMode: sortMode ?? this.sortMode,
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
}
