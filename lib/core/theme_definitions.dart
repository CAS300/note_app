import 'package:flutter/material.dart';
import '../models/app_settings.dart';

/// Centralized theme definitions.
/// Each theme returns a full [ThemeData] so the app can switch at runtime.
class AppThemes {
  AppThemes._();

  static ThemeData resolve(AppThemeId id) {
    switch (id) {
      case AppThemeId.defaultTheme:
        return _defaultTheme();
      case AppThemeId.terminalGreen:
        return _terminalGreenTheme();
    }
  }

  /// Human-readable label for display in settings.
  static String label(AppThemeId id) {
    switch (id) {
      case AppThemeId.defaultTheme:
        return 'Varsayılan (Koyu Mavi)';
      case AppThemeId.terminalGreen:
        return 'Terminal (Yeşil)';
    }
  }

  // ──────────────────────────────────────
  //  A) Default — Deep-blue dark theme
  // ──────────────────────────────────────
  static ThemeData _defaultTheme() {
    const bg = Color(0xFF0F172A);
    const surface = Color(0xFF1E293B);
    const primary = Color(0xFF2563EB);
    const hover = Color(0xFF38BDF8);
    const highlight = Color(0xFF60A5FA);
    const textPrimary = Color(0xFFE2E8F0);
    const textSecondary = Color(0xFF94A3B8);
    const textMuted = Color(0xFF64748B);
    const border = Color(0xFF334155);
    const card = Color(0xFF1E293B);
    const delete = Color(0xFFF87171);

    return _buildTheme(
      bg: bg,
      surface: surface,
      primary: primary,
      hover: hover,
      highlight: highlight,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      border: border,
      card: card,
      delete: delete,
      sidebarBg: const Color(0xFF0B1120),
    );
  }

  // ──────────────────────────────────────
  //  B) Terminal Green
  // ──────────────────────────────────────
  static ThemeData _terminalGreenTheme() {
    const bg = Color(0xFF000000);
    const surface = Color(0xFF0A0A0A);
    const primary = Color(0xFF00FF41);
    const hover = Color(0xFF00C853);
    const highlight = Color(0xFF00E676);
    const textPrimary = Color(0xFF00FF41);
    const textSecondary = Color(0xFFA4FFB0);
    const textMuted = Color(0xFF4CAF50);
    const border = Color(0xFF1B5E20);
    const card = Color(0xFF0D0D0D);
    const delete = Color(0xFFFF5252);

    return _buildTheme(
      bg: bg,
      surface: surface,
      primary: primary,
      hover: hover,
      highlight: highlight,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textMuted: textMuted,
      border: border,
      card: card,
      delete: delete,
      sidebarBg: const Color(0xFF050505),
    );
  }

  // ──────────────────────────────────────
  //  Shared builder
  // ──────────────────────────────────────
  static ThemeData _buildTheme({
    required Color bg,
    required Color surface,
    required Color primary,
    required Color hover,
    required Color highlight,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
    required Color border,
    required Color card,
    required Color delete,
    required Color sidebarBg,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        surface: surface,
        primary: primary,
        secondary: hover,
        onSurface: textPrimary,
        onPrimary: bg,
        outline: border,
      ),
      cardColor: card,
      dividerColor: border,
      textTheme: TextTheme(
        headlineMedium: TextStyle(
            fontSize: 20, fontWeight: FontWeight.w600, color: textPrimary),
        titleMedium: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: textPrimary),
        bodyMedium: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w400, color: textSecondary),
        bodySmall: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w400, color: textMuted),
        labelMedium: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
      ),
      iconTheme: IconThemeData(color: textSecondary, size: 20),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: card,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: bg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: card,
        contentTextStyle: TextStyle(color: textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        textStyle: TextStyle(color: textPrimary, fontSize: 14),
      ),
      // Custom extension: store extra colors in extensions
      extensions: <ThemeExtension<dynamic>>[
        NoteAppColors(
          sidebarBg: sidebarBg,
          hoverBg: hover,
          highlight: highlight,
          deleteColor: delete,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          textMuted: textMuted,
          border: border,
          card: card,
          primary: primary,
        ),
      ],
    );
  }
}

/// Custom color extension for app-specific colors not covered by [ThemeData].
@immutable
class NoteAppColors extends ThemeExtension<NoteAppColors> {
  final Color sidebarBg;
  final Color hoverBg;
  final Color highlight;
  final Color deleteColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final Color card;
  final Color primary;

  const NoteAppColors({
    required this.sidebarBg,
    required this.hoverBg,
    required this.highlight,
    required this.deleteColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.border,
    required this.card,
    required this.primary,
  });

  @override
  NoteAppColors copyWith({
    Color? sidebarBg,
    Color? hoverBg,
    Color? highlight,
    Color? deleteColor,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? border,
    Color? card,
    Color? primary,
  }) {
    return NoteAppColors(
      sidebarBg: sidebarBg ?? this.sidebarBg,
      hoverBg: hoverBg ?? this.hoverBg,
      highlight: highlight ?? this.highlight,
      deleteColor: deleteColor ?? this.deleteColor,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      card: card ?? this.card,
      primary: primary ?? this.primary,
    );
  }

  @override
  NoteAppColors lerp(NoteAppColors? other, double t) {
    if (other == null) return this;
    return NoteAppColors(
      sidebarBg: Color.lerp(sidebarBg, other.sidebarBg, t)!,
      hoverBg: Color.lerp(hoverBg, other.hoverBg, t)!,
      highlight: Color.lerp(highlight, other.highlight, t)!,
      deleteColor: Color.lerp(deleteColor, other.deleteColor, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      card: Color.lerp(card, other.card, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
    );
  }
}
